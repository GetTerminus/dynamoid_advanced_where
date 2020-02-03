module DynamoidAdvancedWhere
  module Nodes
    class BooleanEqualityNode < BaseNode
      delegate :term, to: :field_node

      attr_accessor :field_node, :value

      def initialize(field_node: , value: , **args)
        super(args)
        self.field_node = field_node
        self.value = value
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
          ":#{expression_prefix}V" => cast_value
        }
      end

      private

      def cast_value
        if attribute_config[:store_as_native_boolean]
          value
        elsif value == true
          't'
        else
          'f'
        end
      end

      def attribute_config
        klass.attributes[term]
      end
    end
  end
end
