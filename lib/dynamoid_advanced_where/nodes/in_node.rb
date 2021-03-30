module DynamoidAdvancedWhere
  module Nodes
    class InNode < OperationNode
      def to_expression
        "#{lh_operation.to_expression} IN #{rh_operation.to_expression}"
      end
    end

    module Concerns
      module SupportsIn
        def in?(other_value)
          val = if respond_to?(:parse_right_hand_side)
                  parse_right_hand_side(other_value)
                else
                  other_value
                end

          raise 'Expected parameter of `in?` to be an array' unless val.is_a?(Array)

          InNode.new(
            lh_operation: self,
            rh_operation: ArrayLiteralNode.new(val)
          )
        end
      end
    end
  end
end
