# frozen_string_literal: true

require_relative './filter_builder'

module DynamoidAdvancedWhere
  class QueryMaterializer
    include Enumerable
    attr_accessor :query_builder

    delegate :klass, :start_hash, to: :query_builder
    delegate :table_name, to: :klass
    delegate :to_a, :first, to: :each

    delegate :must_scan?, to: :filter_builder

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

    def each_page_via_query
      query = {
        table_name: table_name,
      }.merge(filter_builder.to_query_filter)

      query[:limit] = query_builder.record_limit if query_builder.record_limit

      page_start = start_hash

      Enumerator.new do |yielder|
        loop do
          results = client.query(query.merge(exclusive_start_key: page_start))

          items = (results.items || []).each do |item|
            klass.from_database(item.symbolize_keys)
          end

          yielder.yield(items, results)

          query[:limit] = query[:limit] - results.items.length if query[:limit]

          break if results.last_evaluated_key.nil? || query[:limit]&.zero?

          (page_start = results.last_evaluated_key)
        end
      end.lazy
    end

    def each_page_via_scan
      query = {
        table_name: table_name,
      }.merge(filter_builder.to_scan_filter)

      query[:limit] = query_builder.record_limit if query_builder.record_limit

      page_start = start_hash

      Enumerator.new do |yielder|
        loop do
          results = client.scan(query.merge(exclusive_start_key: page_start))

          items = (results.items || []).map do |item|
            klass.from_database(item.symbolize_keys)
          end

          yielder.yield(items, results)

          query[:limit] = query[:limit] - results.items.length if query[:limit]

          break if results.last_evaluated_key.nil? || query[:limit]&.zero?

          (page_start = results.last_evaluated_key)
        end
      end.lazy
    end

    def filter_builder
      @filter_builder ||= FilterBuilder.new(
        root_node: query_builder.root_node,
        klass: klass,
      )
    end

    private

    def client
      Dynamoid.adapter.client
    end
  end
end
