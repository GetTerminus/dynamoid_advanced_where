# frozen_string_literal: true

module DynamoidAdvancedWhere
  module Nodes
    class AndNode < BaseNode
      attr_accessor :child_nodes, :negated

      def to_condition_expression
        return if child_nodes.empty?

        "#{@negated ? 'NOT ' : ''}(#{child_nodes.map(&:to_condition_expression).join(') and (')})"
      end

      def negate!
        @negated = !@negated
      end

      def negated?
        !!@negated
      end

      def dup
        super.tap { |n| n.negated = @negated }
      end
    end
  end
end
