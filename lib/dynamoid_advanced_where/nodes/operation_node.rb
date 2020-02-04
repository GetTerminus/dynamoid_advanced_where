# frozen_string_literal: true

module DynamoidAdvancedWhere
  module Nodes
    class OperationNode < BaseNode
      class << self
        attr_accessor :operator
      end

      attr_accessor :lh_operation, :rh_operation

      def initialize(lh_operation:, rh_operation:)
        self.lh_operation = lh_operation
        self.rh_operation = rh_operation
      end

      def dup
        self.class.new(
          lh_operation: lh_operation,
          rh_operation: rh_operation,
          klass: klass
        )
      end

      def to_expression
        "#{lh_operation.to_expression} #{self.class.operator} " \
          "#{rh_operation.to_expression} "
      end

      def expression_attribute_names
        lh_operation.expression_attribute_names.merge(
          rh_operation.expression_attribute_names
        )
      end

      def expression_attribute_values
        lh_operation.expression_attribute_values.merge(
          rh_operation.expression_attribute_values
        )
      end
    end
  end
end
