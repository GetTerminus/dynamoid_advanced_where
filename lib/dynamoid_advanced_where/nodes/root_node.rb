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
    end
  end
end
