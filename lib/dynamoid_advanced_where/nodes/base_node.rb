require 'securerandom'

module DynamoidAdvancedWhere
  module Nodes
    class BaseNode
      attr_accessor :child_nodes, :expression_prefix

      def all_nodes
        [self] + Array.wrap(self.child_nodes).flat_map(&:all_nodes)
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

