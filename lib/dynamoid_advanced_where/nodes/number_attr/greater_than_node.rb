module DynamoidAdvancedWhere
  module Nodes
    module NumberAttr
      class GreaterThanNode < Nodes::GreaterThanNode
        delegate :term, to: :term_node

        attr_accessor :term_node, :value

        def initialize(term_node: , value: , **args)
          if !value.is_a?(Numeric)
            raise ArgumentError, "Unable to perform greater than on value of type #{value.class}"
          end

          super(args)

          self.term_node = term_node
          self.value = value
        end

        def to_condition_expression
          "##{expression_prefix} > :#{expression_prefix}V"
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
