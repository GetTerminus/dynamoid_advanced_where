module DynamoidAdvancedWhere
  module Nodes
    class EqualityNode < BaseNode
      delegate :term, to: :field_node

      attr_accessor :field_node, :value

      def initialize(field_node: , value: , **args)
        super(args)
        self.field_node = field_node
        self.value = value
      end

      def dup
        self.class.new(field_node: field_node, value: value, klass: klass).tap do |e|
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
