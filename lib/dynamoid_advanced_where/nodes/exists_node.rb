module DynamoidAdvancedWhere
  module Nodes
    class ExistsNode < BaseNode
      delegate :term, to: :term_node

      attr_accessor :term_node, :value

      def initialize(term_node: , **args)
        super(args)
        self.term_node = term_node
        self.value = value
      end

      def to_condition_expression
         "attribute_exists(##{expression_prefix}) or ##{expression_prefix} = NOT_NULL"
      end

      def expression_attribute_names
        {
          "##{expression_prefix}" => term
        }
      end
    end
  end
end
