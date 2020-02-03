module DynamoidAdvancedWhere
  module Nodes
    class ExistsNode < BaseNode
      delegate :term, to: :field_node

      attr_accessor :field_node, :value

      def initialize(field_node: , **args)
        super(args)
        self.field_node = field_node
        self.value = value
      end


      def to_condition_expression
         "NOT(attribute_not_exists(##{expression_prefix}) or ##{expression_prefix} = :#{expression_prefix}V2)"
      end

      def expression_attribute_values
        { ":#{expression_prefix}V2" => nil }
      end

      def expression_attribute_names
        {
          "##{expression_prefix}" => term
        }
      end

      def dup
        self.class.new(field_node: field_node, klass: klass)
      end
    end
  end
end
