require 'securerandom'

module DynamoidAdvancedWhere
  module Nodes
    class BaseNode
      attr_accessor :child_nodes, :expression_prefix
     # # Method Nodes
     # def and(other_arg)
     #   create_subnode(AndNode).tap do |and_node|
     #     and_node.child_nodes = [self, other_arg].compact
     #   end
     # end
     # alias & and

     # def or(other_arg)
     #   create_subnode(OrNode).tap do |and_node|
     #     and_node.child_nodes = [self, other_arg].compact
     #   end
     # end
     # alias | or

     # def negate
     #   self.and(nil).tap{|n| n.negate! }
     # end
     # alias ! negate

      def all_nodes
        [self] + Array.wrap(self.child_nodes).flat_map(&:all_nodes)
      end


      def expression_attribute_names
        {}
      end

      def expression_attribute_values
        {}
      end

      # def to_condition_expression

      # end

      # def flatten_tree!
      #   Array.wrap(self.child_nodes).map(&:flatten_tree!)
      #   self.flatten_logic!
      # end

      # def flatten_logic!

      # end

      # def expression_prefix
      #   @expression_prefix ||= SecureRandom.hex
      # end
    end
  end
end

