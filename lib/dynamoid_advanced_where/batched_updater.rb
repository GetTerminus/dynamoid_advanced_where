# frozen_string_literal: true

module DynamoidAdvancedWhere
  class BatchedUpdater
    DEEP_MERGE_ATTRIBUTES = %i[expression_attribute_names expression_attribute_values].freeze

    attr_accessor :query_builder, :_set_values, :_array_appends, :_set_appends, :_increments
    delegate :klass, to: :query_builder

    def initialize(query_builder:)
      self.query_builder = query_builder
      self._set_values = {}
      self._set_appends = []
      self._array_appends = []
      self._increments = Hash.new(0)
    end

    def apply(hash_key, range_key = nil)
      key_args = {
        table_name: klass.table_name,
        return_values: 'ALL_NEW',
        key: {
          klass.hash_key => hash_key,
          klass.range_key => range_key
        }.delete_if { |k, _v| k.nil? }
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
          _set_appends << { k => v.to_set }
        when :array
          _array_appends << { k => v }
        else
          raise 'can only append to sets or arrays'
        end
      end

      self
    end

    def increment(*fields, by: 1)
      fields.each { |field| _increments[field] += by }
      self
    end

    def decrement(*fields, by: 1)
      increment(*fields, by: -1 * by)
      self
    end

    private

    def merge_multiple_sets(items_to_merge, result_base: {})
      default = { collected_update_expression: [] }
      result = result_base.merge(default)
      items_to_merge.each do |update_data|
        result[:collected_update_expression] << update_data.delete(:collected_update_expression)
        result.merge!(update_data, &method(:hash_extendeer))
      end

      result[:collected_update_expression].flatten!
      result[:collected_update_expression].reject!(&:blank?)

      return default if result[:collected_update_expression].empty?

      result
    end

    def field_update_arguments
      merge_multiple_sets([set_values_update_args])
    end

    def update_item_arguments
      filter = merge_multiple_sets(
        [
          field_update_arguments,
          add_update_args,
        ],
        result_base: filter_builder.to_scan_filter,
      )

      filter[:update_expression] = filter.delete(:collected_update_expression).join(' ')
      filter[:condition_expression] = filter.delete(:filter_expression)

      filter
    end

    def args_to_update_command(update_args, command:)
      return {} if update_args[:collected_update_expression].empty?

      update_args.merge!(
        collected_update_expression: [
          "#{command} #{update_args[:collected_update_expression].join(', ')}"
        ]
      )
    end

    def set_values_update_args
      args_to_update_command(
        merge_multiple_sets(
          [
            explicit_set_args,
            list_append_for_arrays,
            increment_field_updates
          ]
        ),
        command: 'SET'
      )
    end

    def add_update_args
      args_to_update_command(list_append_for_sets, command: 'ADD')
    end

    def explicit_set_args
      builder_hash = { collected_update_expression: [] }

      _set_values.each_with_object(builder_hash) do |(k, v), h|
        prefix = merge_in_attr_placeholders(h, k, v)
        h[:collected_update_expression] << "##{prefix} = :#{prefix}"
      end
    end


    def increment_field_updates
      return {} if _increments.empty?

      zero_prefix = SecureRandom.hex

      builder_hash = {
        collected_update_expression: [],
        expression_attribute_values: {
          ":#{zero_prefix}": 0
        }
      }

      _increments.each_with_object(builder_hash) do |(field, change), h|
        prefix = merge_in_attr_placeholders(h, field, change)
        builder_hash[:collected_update_expression] << "##{prefix} = if_not_exists(##{prefix}, :#{zero_prefix}) + :#{prefix}"
      end
    end

    def list_append_for_sets
      builder_hash = { collected_update_expression: [] }

      _set_appends.each_with_object(builder_hash) do |to_append, h|
        to_append.each do |k, v|
          prefix = merge_in_attr_placeholders(h, k, v)
          builder_hash[:collected_update_expression] << "##{prefix} :#{prefix}"
        end
      end
    end

    def list_append_for_arrays
      empty_list_prefix = SecureRandom.hex

      builder_hash = {
        collected_update_expression: [],
        expression_attribute_values: {
          ":#{empty_list_prefix}": []
        }
      }

      update_args = _array_appends.each_with_object(builder_hash) do |to_append, h|
        to_append.each do |k, v|
          prefix = merge_in_attr_placeholders(h, k, v)
          builder_hash[:collected_update_expression] << "##{prefix}  = list_append(if_not_exists(##{prefix}, :#{empty_list_prefix}), :#{prefix})"
        end
      end

      builder_hash[:collected_update_expression].empty? ? {} : update_args
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
            ":#{prefix}" => dump(value, klass.attributes[field_name])
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
        root_node: query_builder.root_node,
        klass: klass,
      )
    end

    def dump(value, config)
      Dynamoid::Dumping.dump_field(value, config)
    end
  end
end
