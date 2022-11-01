# frozen_string_literal: true

require 'securerandom'

module DynamoidAdvancedWhere
  module Nodes
    class ArrayLiteralNode
      attr_accessor :value, :attr_prefix
      def initialize(value)
        self.value = value
        self.attr_prefix = SecureRandom.hex
        freeze
      end

      def to_expression
        values = value.each_with_index.map do |_, idx|
          ":#{attr_prefix}#{idx}"
        end
        "(#{values.join(', ')})"
      end

      def expression_attribute_names
        {}
      end

      def expression_attribute_values
        value.each_with_index.map do |val, idx|
          [":#{attr_prefix}#{idx}", val]
        end.to_h
      end
    end
  end
end
