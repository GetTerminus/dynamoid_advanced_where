# frozen_string_literal: true

require_relative './filter_builder'

module DynamoidAdvancedWhere
  class QueryMaterializer
    include Enumerable
    attr_accessor :query_builder

    delegate :klass, :start_hash, to: :query_builder
    delegate :table_name, to: :klass
    delegate :to_a, :first, to: :each

    def initialize(query_builder:)
      self.query_builder = query_builder
    end

    def all
      each.to_a
    end

    def each(&blk)
      return enum_for(:each) unless blk

      records.each(&blk)
    end
    alias find_each each

    def each_page(&blk)
      return enum_for(:each_page) unless blk

      pages.each(&blk)
    end

    def records
      pages.flat_map { |i, _| i }
    end

    def pages
      if must_scan?
        each_page_via_scan
      else
        each_page_via_query
      end
    end

    def enumerate_results(starting_query)
      query = starting_query.dup

      unless query_builder.projected_fields.empty?
        query[:select] = 'SPECIFIC_ATTRIBUTES'
        query[:projection_expression] = query_builder.projected_fields.map(&:to_s).join(',')
      end

      query[:limit] = query_builder.record_limit if query_builder.record_limit

      query[:exclusive_start_key] = start_hash

      Enumerator.new do |yielder|
        loop do
          results = yield(query)

          yielder.yield(construct_items(results.items), results)

          query[:limit] = query[:limit] - results.items.length if query[:limit]

          break if results.last_evaluated_key.nil? || query[:limit]&.zero?

          query[:exclusive_start_key] = results.last_evaluated_key
        end
      end.lazy
    end

    def construct_items(items)
      (items || []).map do |item|
        klass.from_database(item)
      end
    end

    def each_page_via_query
      query = {
        table_name: table_name,
        index_name: selected_index_for_query,
        scan_index_forward: query_builder.scanning_index_forward,
      }.merge(filter_builder.to_query_filter)

      enumerate_results(query) do |q|
        client.query(q)
      end
    end

    def each_page_via_scan
      raise 'Unable to scan a table backwards' unless query_builder.scanning_index_forward

      query = {
        table_name: table_name,
      }.merge(filter_builder.to_scan_filter)

      enumerate_results(query) do |q|
        client.scan(q)
      end
    end

    def filter_builder
      @filter_builder ||= FilterBuilder.new(
        root_node: query_builder.root_node,
        klass: klass,
      )
    end

    # Pick the index to query.
    #   1) The first index chosen should be one that has the range and hash key satisfied.
    #   2) The second should be one that has the hash key
    def selected_index_for_query
      possible_fields = filter_builder.extractable_fields_for_hash_and_range

      satisfiable_indexes.each do |name, definition|
        next unless possible_fields.key?(definition[:hash_key]) &&
                    possible_fields.key?(definition[:range_key])

        filter_builder.select_node_for_range_key(possible_fields[definition[:range_key]])
        filter_builder.select_node_for_query_filter(possible_fields[definition[:hash_key]])

        return name
      end

      # Just take the first matching query then
      name, definition = satisfiable_indexes.first
      filter_builder.select_node_for_query_filter(possible_fields[definition[:hash_key]])
      filter_builder.select_node_for_range_key(possible_fields[definition[:range_key]]) unless possible_fields[definition[:range_key]].blank?

      name
    end

    def must_scan?
      satisfiable_indexes.empty?
    end

    # find all indexes where we have a predicate on the hash key
    def satisfiable_indexes
      possible_fields = filter_builder.extractable_fields_for_hash_and_range

      all_possible_indexes.select do |_, definition|
        possible_fields.key?(definition[:hash_key])
      end
    end

    def all_possible_indexes
      # The nil index name is the table itself
      idx = { nil => { hash_key: klass.hash_key.to_s, range_key: klass.range_key.to_s } }

      klass.indexes.each do |_, definition|
        next unless definition.projected_attributes == :all

        idx[definition.name] = { hash_key: definition.hash_key.to_s, range_key: definition.range_key.to_s }
      end

      idx
    end

    private

    def client
      Dynamoid.adapter.client
    end
  end
end
