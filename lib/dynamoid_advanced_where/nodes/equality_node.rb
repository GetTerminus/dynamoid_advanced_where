module DynamoidAdvancedWhere
  module Nodes
    class EqualityNode < BaseNode
      delegate :term, to: :term_node

      attr_accessor :term_node, :value

      def initialize(term_node: , value: , **args)
        super(args)
        self.term_node = term_node
        self.value = value
      end

      def dup
        self.class.new(term_node: term_node, value: value, klass: klass).tap do |e|
          e.child_nodes = dup_children
        end
      end

      def to_condition_expression
        "##{expression_prefix} = :#{expression_prefix}V"
      end

      def expression_attribute_names
        {
          "##{expression_prefix}" => term
        }
      end

      def expression_attribute_values
        {
          ":#{expression_prefix}V" => value
        }
      end
    end
  end
end
