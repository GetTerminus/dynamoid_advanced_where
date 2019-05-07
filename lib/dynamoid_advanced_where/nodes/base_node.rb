require 'securerandom'

module DynamoidAdvancedWhere
  module Nodes
    class BaseNode
      attr_accessor :klass, :child_nodes, :expression_prefix

      def initialize(klass: nil, &blk)
        self.klass = klass
        self.child_nodes = []
        evaluate_block(blk) if blk
      end

      def dup
        build_dup.tap do |e|
          e.child_nodes = dup_children
        end
      end

      def build_dup
        self.class.new(klass: klass)
      end

      def evaluate_block(blk)
        self.and(self.instance_eval(&blk))
      end

      def method_missing(method, *args, &blk)
        if allowed_field?(method)
          create_subnode(TermNode, term: method, &blk)
        else
          super
        end
      end

      def respond_to_missing?(method, _)
        allowed_field?(method)
      end

      def allowed_field?(method)
        klass.attributes.has_key?(method.to_sym)
      end

      # Method Nodes
      def and(other_arg)
        create_subnode(AndNode).tap do |and_node|
          and_node.child_nodes = [self, other_arg].compact
        end
      end
      alias & and

      def or(other_arg)
        create_subnode(OrNode).tap do |and_node|
          and_node.child_nodes = [self, other_arg].compact
        end
      end
      alias | or

      def negate
        self.and(nil).tap{|n| n.negate! }
      end
      alias ! negate

      def all_nodes
        [self] + Array.wrap(self.child_nodes).flat_map(&:all_nodes)
      end


      def expression_attribute_names
        {}
      end

      def expression_attribute_values
        {}
      end

      def to_condition_expression

      end

      def flatten_tree!
        Array.wrap(self.child_nodes).map(&:flatten_tree!)
        self.flatten_logic!
      end

      def flatten_logic!

      end

      def expression_prefix
        @expression_prefix ||= SecureRandom.hex
      end

      private
      def create_subnode(node_klass, args = {})
        node_klass.new({klass: klass}.merge(args))
      end

      def attribute_config
        klass.attributes[term]
      end

      def dup_children
        child_nodes.is_a?(Array) ? child_nodes.map(&:dup) : child_nodes.dup
      end
    end
  end
end

