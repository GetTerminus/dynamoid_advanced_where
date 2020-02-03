module DynamoidAdvancedWhere
  module Nodes
    module DateAttr
      class LessThanNode < BaseNode
        delegate :term, to: :field_node

        attr_accessor :field_node, :value

        def initialize(field_node: , value: , **args)
          super(args)
          self.field_node = field_node

          if !value.is_a?(Date) || value.is_a?(DateTime)
            raise ArgumentError, "Unable to perform less than on date with a value of type #{value.class}. Expected Date"
          end

          if attribute_config[:store_as_string]
            raise ArgumentError, 'Unable to perform less than on value of type Date unless stored as an integer'
          end

          self.value = (value - Dynamoid::Persistence::UNIX_EPOCH_DATE).to_i
        end

        def to_condition_expression
          "##{expression_prefix} < :#{expression_prefix}V"
        end

        def expression_attribute_names
          {
            "##{expression_prefix}" => term
          }
        end

        def expression_attribute_values
          {
            ":#{expression_prefix}V" => value
          }
        end

        def build_dup
          self.class.new(field_node: field_node, value: value, klass: klass)
        end
      end
    end
  end
end
