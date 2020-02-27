require_relative './filter_builder'

module DynamoidAdvancedWhere
  class QueryMaterializer
    include Enumerable
    attr_accessor :query_builder, :start_key

    delegate :klass, to: :query_builder
    delegate :table_name, to: :klass
    delegate :to_a, :first, to: :each

    delegate :must_scan?, to: :filter_builder

    def initialize(query_builder:)
      self.query_builder = query_builder
    end

    def all
      each.to_a
    end

    def start(key_hash)
      return self if key_hash.nil? || key_hash.empty?

      @start_key = key_hash
      self
    end

    def each(&blk)
      return enum_for(:each) unless blk

      if must_scan?
        each_via_scan(&blk)
      else
        each_via_query(&blk)
      end
    end

    def each_via_query
      query = {
        table_name: table_name
      }.merge(filter_builder.to_query_filter)

      loop do
        results = client.query(query.merge(exclusive_start_key: @start_key))

        @start_key = results.last_evaluated_key
        if results.items
          results.items.each do |item|
            yield klass.from_database(item.symbolize_keys)
          end
        end
        break if @start_key.nil?
      end
    end

    def each_via_scan
      query = {
        table_name: table_name
      }.merge(filter_builder.to_scan_filter)

      loop do
        results = client.scan(query.merge(exclusive_start_key: @start_key))

        @start_key = results.last_evaluated_key
        if results.items
          results.items.each do |item|
            yield klass.from_database(item.symbolize_keys)
          end
        end
        break if @start_key.nil?
      end
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