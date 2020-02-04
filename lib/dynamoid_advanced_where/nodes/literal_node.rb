# frozen_string_literal: true

require 'securerandom'

module DynamoidAdvancedWhere
  module Nodes
    class LiteralNode
      attr_accessor :value, :attr_prefix
      def initialize(value)
        self.value = value
        self.attr_prefix = SecureRandom.hex
      end

      def to_expression
        ":#{attr_prefix}"
      end

      def expression_attribute_names
        {}
      end

      def expression_attribute_values
        { ":#{attr_prefix}" => value }
      end
    end
  end
end
