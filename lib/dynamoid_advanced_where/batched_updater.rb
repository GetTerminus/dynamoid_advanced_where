
module DynamoidAdvancedWhere
  class BatchedUpdater
    DEEP_MERGE_ATTRIBUTES = %i[expression_attribute_names expression_attribute_values]

    attr_accessor :query_builder, :_set_values, :_array_appends, :_set_appends
    delegate :klass, to: :query_builder

    def initialize(query_builder:)
      self.query_builder = query_builder
      self._set_values = {}
      self._set_appends = []
      self._array_appends = []
    end

    def apply(hash_key, range_key = nil)
      key_args = {
        table_name: klass.table_name,
        return_values: 'ALL_NEW',
        key: {
          klass.hash_key => hash_key,
          klass.range_key => range_key,
        }.delete_if{|k,v| k.nil? }
      }
      resp = client.update_item(update_item_arguments.merge(key_args))

      klass.from_database(resp.attributes)
    rescue Aws::DynamoDB::Errors::ConditionalCheckFailedException
    end

    def set_values(vals)
      _set_values.merge!(vals)
      self
    end

    def append_to(appends)
      appends.each do |k, v|
        case klass.attributes[k.to_sym][:type]
        when :set
          _set_appends << {k => v.to_set}
        when :array
          _array_appends << {k => v}
        else
          raise 'can only append to sets or arrays'
        end
      end

      self
    end

    private

    def field_update_arguments
      all_update_args = {update_expression: []}

      [
        set_values_update_args
      ].each do |update_data|
        all_update_args[:update_expression] << update_data.delete(:update_expression)
        all_update_args.merge!(update_data, &method(:hash_extendeer))
      end
      all_update_args[:update_expression] = all_update_args[:update_expression].join(', ')

      all_update_args
    end

    def update_item_arguments
      # Grab conditions for row filtering
      filter = filter_builder.to_scan_filter

      update_expressions = []
      [
        field_update_arguments,
        add_update_args
      ].each do |partial_args|
        update_expressions << partial_args.delete(:update_expression)
        filter.merge!(partial_args, &method(:hash_extendeer))
      end

      filter[:condition_expression] = filter.delete(:filter_expression)
      filter[:update_expression] = update_expressions.join(' ')

      filter
    end


    def set_values_update_args
      final_args = {}
      all_update_expressions = []

      [
        explicit_set_args,
        list_append_for_arrays,
      ].each_with_object(final_args) do |new_args, hsh|
        all_update_expressions << new_args.delete(:set_expressions)
        hsh.merge!(new_args, &method(:hash_extendeer))
      end

      update_expressions = all_update_expressions.flatten.reject(&:blank?)
      final_args[:update_expression] = "SET #{update_expressions.join(', ')}"

      final_args
    end

    def add_update_args
      final_args = {}
      all_update_expressions = []

      [
        list_append_for_sets,
      ].each_with_object(final_args) do |new_args, hsh|
        all_update_expressions << new_args.delete(:set_expressions)
        hsh.merge!(new_args, &method(:hash_extendeer))
      end
      all_update_expressions.reject!(&:blank?)

      return {} if all_update_expressions.empty?

      final_args[:update_expression] = "ADD #{all_update_expressions.join(', ')}"

      final_args
    end


    def explicit_set_args
      builder_hash = Hash.new{|h,k| h[k] = Hash.new{|h2, k2| h2[k2] = {} } }

      set_expressions = []
      obj = _set_values.each_with_object(builder_hash) do |(k, v), h|
        prefix = merge_in_attr_placeholders(h, k, v)
        set_expressions << "##{prefix} = :#{prefix}"
      end

      obj[:set_expressions] = set_expressions

      obj
    end

    def list_append_for_sets
      builder_hash = Hash.new{|h,k| h[k] = Hash.new{|h2, k2| h2[k2] = {} } }

      set_expressions = []

      obj = _set_appends.each_with_object(builder_hash) do |to_append, h|
        to_append.each do |k,v|
          prefix = merge_in_attr_placeholders(h, k, v)
          set_expressions << "##{prefix} :#{prefix}"
        end
      end

      obj[:set_expressions] = set_expressions

      obj
    end

    def list_append_for_arrays
      builder_hash = Hash.new{|h,k| h[k] = Hash.new{|h2, k2| h2[k2] = {} } }

      set_expressions = []
      empty_list_prefix = SecureRandom.hex

      builder_hash[:expression_attribute_values][":#{empty_list_prefix}"] = []

      obj = _array_appends.each_with_object(builder_hash) do |to_append, h|
        to_append.each do |k,v|
          prefix = merge_in_attr_placeholders(h, k, v)
          set_expressions << "##{prefix}  = list_append(if_not_exists(##{prefix}, :#{empty_list_prefix}), :#{prefix})"
        end
      end

      return {} if set_expressions.empty?

      obj[:set_expressions] = set_expressions

      obj
    end

    def merge_in_attr_placeholders(hsh, field_name, value)
      prefix, new_data = prefixerize(field_name, value)

      hsh.merge!(new_data, &method(:hash_extendeer))

      prefix
    end

    def prefixerize(field_name, value)
      prefix = SecureRandom.hex

      [
        prefix,
        {
          expression_attribute_names: { "##{prefix}" => field_name },
          expression_attribute_values: {
            ":#{prefix}" => klass.dump_field(
              value,
                klass.attributes[field_name]
            )
          }
        }
      ]
    end

    def hash_extendeer(key, old_value, new_value)
      return new_value unless key.in?(DEEP_MERGE_ATTRIBUTES)
      old_value.merge(new_value)
    end

    def client
      Dynamoid.adapter.client
    end

    def filter_builder
      @filter_builder ||= FilterBuilder.new(
        query_builder: self.query_builder,
        klass: klass,
      )
    end
  end
end
