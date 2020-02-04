module DynamoidAdvancedWhere
  module Nodes
    class LessThanNode < OperationNode
      include Concerns::Negatable

      self.operator = '<'
    end

    module Concerns
      module SupportsGreaterThan
        def lt(other_value)
          val = if respond_to?(:parse_right_hand_side)
                  parse_right_hand_side(other_value)
                else
                  other_value
                end

          LessThanNode.new(
            lh_operation: self,
            rh_operation: LiteralNode.new(val)
          )
        end
        alias < lt
      end
    end
  end
end
