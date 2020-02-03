module DynamoidAdvancedWhere
  module Nodes
    module NumberAttr
      class LessThanNode < BaseNode
        delegate :term, to: :field_node

        attr_accessor :field_node, :value

        def initialize(field_node: , value: , **args)
          if !value.is_a?(Numeric)
            raise ArgumentError, "Unable to perform less than on value of type #{value.class}"
          end

          super(args)

          self.field_node = field_node
          self.value = value
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
      end
    end
  end
end
