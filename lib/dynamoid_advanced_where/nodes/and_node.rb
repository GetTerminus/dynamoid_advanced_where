# frozen_string_literal: true

module DynamoidAdvancedWhere
  module Nodes
    module Concerns
      module SupportsLogicalAnd
        def and(other_value)
          AndNode.new(self, other_value)
        end
        alias & and
      end
    end

    # I know this is weird but it prevents a circular dependency
    require_relative './not'

    class AndNode < BaseNode
      include Concerns::Negatable
      attr_accessor :child_nodes

      def initialize(*child_nodes)
        self.child_nodes = child_nodes.freeze
        freeze
      end

      def to_expression
        return if child_nodes.empty?

        "(#{child_nodes.map(&:to_expression).join(') and (')})"
      end

      def expression_attribute_names
        child_nodes.map(&:expression_attribute_names).inject({}, &:merge!)
      end

      def expression_attribute_values
        child_nodes.map(&:expression_attribute_values).inject({}, &:merge!)
      end

      def and(other_value)
        AndNode.new(other_value, *child_nodes)
      end
      alias & and
    end
  end
end
