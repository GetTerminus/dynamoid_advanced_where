module DynamoidAdvancedWhere
  module Nodes
    class RootNode < BaseNode
      attr_accessor :klass

      def initialize(klass:, &blk)
        self.klass = klass
        evaluate_block(blk)
      end

      def evaluate_block(blk)
        self.child_nodes = [
          self.instance_eval(&blk)
        ].compact
      end

      def to_expression
        child_nodes.first.to_expression if child_nodes.length.positive?
      end

      def method_missing(method, *args, &blk)
        if allowed_field?(method)
          FieldNode.create_node(klass: klass, field_name: method)
        else
          super
        end
      end

      def respond_to_missing?(method, _i)
        allowed_field?(method)
      end

      def allowed_field?(method)
        klass.attributes.key?(method.to_sym)
      end

      # def combine_with!(other_root_node, combinator)
      #   new_child = create_subnode(combinator).tap do |new_node|
      #     new_node.child_nodes = (
      #       self.child_nodes + other_root_node.child_nodes
      #     ).compact
      #   end

      #   new_child.flatten_tree!

      #   self.child_nodes = [new_child]
      # end
    end
  end
end
