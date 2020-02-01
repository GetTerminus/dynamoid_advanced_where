# frozen_string_literal: true

require_relative './filter_builder'

module DynamoidAdvancedWhere
  class QueryMaterializer
    include Enumerable
    attr_accessor :query_builder

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

    def each(&blk)
      return enum_for(:each) unless blk

      each_page.flat_map{|i, _| i }.each(&blk)
    end

    def each_page
      if must_scan?
        each_page_via_scan
      else
        each_page_via_query
      end
    end

    def each_page_via_query
      query = {
        table_name: table_name
      }.merge(filter_builder.to_query_filter)

      Enumerator.new do |yielder|
        start_key = nil
        loop do
          results = client.query(query.merge(exclusive_start_key: start_key))

          start_key = results.last_evaluated_key

          items = (results.items || []).map do |i|
            klass.from_database(i.symbolize_keys)
          end

          yielder.yield(items, results)

          break if start_key.nil?
        end
      end.lazy
    end

    def each_page_via_scan
      query = {
        table_name: table_name
      }.merge(filter_builder.to_scan_filter)

      start_key = nil
      Enumerator.new do |yielder|
        loop do
          results = client.scan(query.merge(exclusive_start_key: start_key))

          start_key = results.last_evaluated_key

          items = (results.items || []).map do |i|
            klass.from_database(i.symbolize_keys)
          end

          yielder.yield(items, results)

          break if start_key.nil?
        end
      end.lazy
    end

    def filter_builder
      @filter_builder ||= FilterBuilder.new(
        query_builder: query_builder,
        klass: klass,
      )
    end

    private

    def client
      Dynamoid.adapter.client
    end
  end
end
