module DynamoidAdvancedWhere
  module Nodes
    class GreaterThanNode < OperationNode
      self.operator = '>'
    end

    module Concerns
      module SupportsGreaterThan
        def gt(other_value)
          val = if respond_to?(:parse_right_hand_side)
                  parse_right_hand_side(other_value)
                else
                  other_value
                end

          GreaterThanNode.new(
            lh_operation: self,
            rh_operation: LiteralNode.new(val)
          )
        end
        alias > gt
      end
    end
  end
end
