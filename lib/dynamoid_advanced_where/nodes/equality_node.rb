# frozen_string_literal: true

require_relative './operation_node'
require_relative './not'

module DynamoidAdvancedWhere
  module Nodes
    class EqualityNode < OperationNode
      include Concerns::Negatable

      self.operator = '='
    end

    module Concerns
      module SupportsEquality
        def eq(other_value)
          val = if respond_to?(:parse_right_hand_side)
                  parse_right_hand_side(other_value)
                else
                  other_value
                end

          EqualityNode.new(
            lh_operation: self,
            rh_operation: LiteralNode.new(val)
          )
        end
        alias == eq

        def not_eq(other_value)
          eq(other_value).negate
        end
        alias != not_eq
      end
    end
  end
end
