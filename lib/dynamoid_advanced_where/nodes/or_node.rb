module DynamoidAdvancedWhere
  module Nodes
    class OrNode < BaseNode
      include Concerns::Negatable
      attr_accessor :child_nodes

      def initialize(*child_nodes)
        self.child_nodes = child_nodes
      end

      def to_expression
        return if child_nodes.empty?

        "(#{child_nodes.map(&:to_expression).join(') or (')})"
      end

      def all_nodes
        [self] + child_nodes
      end

      def or(other_value)
        child_nodes << other_value
      end
      alias | or
    end

    module Concerns
      module SupportsLogicalOr
        def or(other_value)
          OrNode.new(self, other_value)
        end
        alias | or
      end
    end
  end
end
