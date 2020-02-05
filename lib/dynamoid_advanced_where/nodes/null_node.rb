# frozen_string_literal: true

require 'securerandom'

module DynamoidAdvancedWhere
  module Nodes
    class NullNode
      def initialize
        freeze
      end

      def to_expression
        ''
      end

      def expression_attribute_names
        {}
      end

      def expression_attribute_values
        {}
      end
    end
  end
end
