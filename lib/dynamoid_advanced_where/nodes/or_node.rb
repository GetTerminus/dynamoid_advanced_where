module DynamoidAdvancedWhere
  module Nodes
    class OrNode < BaseNode
      include Concerns::Negatable
      attr_accessor :child_nodes

      def initialize(*child_nodes)
        self.child_nodes = child_nodes.freeze
        freeze
      end

      def to_expression
        return if child_nodes.empty?

        "(#{child_nodes.map(&:to_expression).join(') or (')})"
      end

      def expression_attribute_names
        child_nodes.map(&:expression_attribute_names).inject({}, &:merge!)
      end

      def expression_attribute_values
        child_nodes.map(&:expression_attribute_values).inject({}, &:merge!)
      end

      def or(other_value)
        OrNode.new(other_value, *child_nodes)
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
