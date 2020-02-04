module DynamoidAdvancedWhere
  module Nodes
    class IncludesNode < OperationNode
      def to_expression
        "contains(
          #{lh_operation.to_expression},
          #{rh_operation.to_expression}
        )"
      end
    end

    module Concerns
      module SupportsIncludes
        def includes?(other_value)
          val = if respond_to?(:parse_right_hand_side)
                  parse_right_hand_side(other_value)
                else
                  other_value
                end

          IncludesNode.new(
            lh_operation: self,
            rh_operation: LiteralNode.new(val)
          )
        end
      end
    end
  end
end
