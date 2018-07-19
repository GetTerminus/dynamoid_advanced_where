require_relative './filter_builder'

module DynamoidAdvancedWhere
  class UpdateWithQuery
    DEEP_MERGE_ATTRIBUTES = %i[expression_attribute_names expression_attribute_values]
    include Enumerable
    attr_accessor :query_builder, :set_values

    delegate :klass, to: :query_builder

    def initialize(query_builder:)
      self.query_builder = query_builder
      self.set_values = {}
    end

    def upsert(*args)
      set_values.merge!(args.extract_options!)

      hash_key, range_key = args

      resp = client.update_item(upsert_arguments.merge(
        table_name: klass.table_name,
        return_values: 'ALL_NEW',
        key: {
          klass.hash_key => hash_key,
          klass.range_key => range_key,
        }.delete_if{|k,v| k.nil? }
      ))

      klass.from_database(resp.attributes)
    rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
    end

    def upsert_arguments
      filter = filter_builder.to_scan_filter.merge(set_values_params, &method(:hash_extendeer))
      filter[:condition_expression] = filter.delete(:filter_expression)
      filter
    end

    def hash_extendeer(key, old_value, new_value)
      return new_value unless key.in?(DEEP_MERGE_ATTRIBUTES)
      old_value.merge(new_value)
    end

    def set_values_params
      builder_hash = Hash.new{|h,k| h[k] = Hash.new{|h2, k2| h2[k2 = {} ]} }

      set_expressions = []
      obj = set_values.each_with_object(builder_hash) do |(k, v), h|
        prefix = SecureRandom.hex
        h[:expression_attribute_names]["##{prefix}"] = k
        h[:expression_attribute_values][":#{prefix}"] = klass.dump_field(
          v,
          klass.attributes[k]
        )
        set_expressions << "##{prefix} = :#{prefix}"
      end

      obj[:update_expression] = "SET #{set_expressions.join(', ')}"

      obj
    end


    def filter_builder
      @filter_builder ||= FilterBuilder.new(
        query_builder: self.query_builder,
        klass: klass,
      )
    end

    private
    def client
      Dynamoid.adapter.client
    end
  end
end
