# frozen_string_literal: true

require 'forwardable'

module DynamoidAdvancedWhere
  module Nodes
    module Concerns
      module Negatable
        def negate
          NotNode.new(sub_node: self)
        end
        alias ! negate
      end
    end

    # I know this is weird but it prevents a circular dependency
    require_relative './and_node'
    require_relative './or_node'

    class NotNode
      extend Forwardable
      include Concerns::SupportsLogicalAnd
      include Concerns::SupportsLogicalOr

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
  end
end
