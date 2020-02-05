# frozen_string_literal: true

require 'forwardable'

module DynamoidAdvancedWhere
  module Nodes
    class NotNode
      extend Forwardable

      attr_accessor :sub_node

      def_delegators :@sub_node,
                     :expression_attribute_names,
                     :expression_attribute_values

      def initialize(sub_node:)
        self.sub_node = sub_node
        freeze
      end

      def to_expression
        "NOT(#{sub_node.to_expression})"
      end
    end

    module Concerns
      module Negatable
        def negate
          NotNode.new(sub_node: self)
        end
        alias ! negate
      end
    end
  end
end
