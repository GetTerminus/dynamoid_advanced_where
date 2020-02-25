require_relative './filter_builder'

module DynamoidAdvancedWhere
  class QueryMaterializer
    include Enumerable
    attr_accessor :query_builder, :limit, :start_key, :last_evaluated_key

    delegate :klass, to: :query_builder
    delegate :table_name, to: :klass
    delegate :to_a, :first, to: :each

    delegate :must_scan?, to: :filter_builder

    def initialize(query_builder:)
      self.query_builder = query_builder
      self.limit = {}
      self.start_key = { exclusive_start_key: nil }
    end

    def all
      @start_key = {}
      each.to_a
    end

    def record_limit(num)
      @limit = { limit: num }
      result = QueryResults.new(each.to_a)
      result.last_evaluated_key = @last_evaluated_key
      result
    end

    def start(key_hash)
      @start_key = { exclusive_start_key: key_hash }
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
        table_name: table_name,
      }.merge(filter_builder.to_query_filter)

      results = client.query(query)

      if results.items
        results.items.each do |item|
          yield klass.from_database(item.symbolize_keys)
        end
      end
    end

    def each_via_scan
      query = {
        table_name: table_name
      }.merge(filter_builder.to_scan_filter).merge(limit).merge(start_key)

      results = client.scan(query)

      if results.items
        @last_evaluated_key = results.last_evaluated_key
        results.items.each do |item|
          yield klass.from_database(item.symbolize_keys)
        end
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

class QueryResults < Array
  attr_accessor :last_evaluated_key
end