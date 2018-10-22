module DynamoidAdvancedWhere
  module Nodes
    class RootNode < BaseNode
      def evaluate_block(blk)
        self.child_nodes = [
          self.instance_eval(&blk)
        ].compact
      end

      def to_condition_expression
        child_nodes.first.to_condition_expression unless child_nodes.empty?
      end

      def combine_with!(other_root_node, combinator)
        new_child = create_subnode(combinator).tap do |new_node|
          new_node.child_nodes = (
            self.child_nodes + other_root_node.child_nodes
          ).compact
        end

        self.child_nodes = [new_child]
      end
    end
  end
end
