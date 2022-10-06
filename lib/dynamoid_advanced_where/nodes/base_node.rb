# frozen_string_literal: true

require 'securerandom'

module DynamoidAdvancedWhere
  module Nodes
    class BaseNode
      attr_accessor :expression_prefix

      def expression_attribute_names
        {}
      end

      def expression_attribute_values
        {}
      end
    end
  end
end
