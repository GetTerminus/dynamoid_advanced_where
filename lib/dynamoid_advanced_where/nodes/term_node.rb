module DynamoidAdvancedWhere
  module Nodes
    class TermNode < BaseNode
      attr_accessor :term

      delegate :expression_attribute_names, :expression_attribute_values,
        :to_condition_expression, to: :child_nodes, allow_nil: true

      def initialize(term: , **args)
        super(args)

        self.term = term
        exists!
      end

      def exists!
        self.child_nodes = create_subnode(ExistsNode, term_node: self)
      end

      def eq(other_value)
        self.child_nodes = case other_value
                           when String
                             create_subnode(
                               EqualityNode,
                               term_node: self,
                               value: other_value
                             )
                           else
                             raise "Not sure what to do with #{other_value}"
                           end

        self
      end
      alias == eq

      def greater_than(other_value)
        if attribute_config[:type] != :number
          raise ArgumentError, "Unable to perform greater than on field of type #{attribute_config[:type]}"
        end

        unless other_value.is_a?(Numeric)
          raise ArgumentError, "Unable to perform greater than on value of type #{other_value.class}"
        end

        self.child_nodes = case other_value
                           when Numeric
                             create_subnode(
                               GreaterThanNode,
                               term_node: self,
                               value: other_value
                             )
                           else
                             raise "Not sure what to do with #{other_value}"
                           end

        self
      end
      alias > greater_than

      def less_than(other_value)
        klass = LessThanNode.determine_subtype(
          attribute_config,
          other_value
        )

        self.child_nodes = create_subnode(
          klass,
          term_node: self,
          value: other_value
        )

        self
      end
      alias < less_than

      def ne(other_value)
        eq(other_value).negate
      end
      alias != ne


      private
      def attribute_config
        klass.attributes[term]
      end
    end
  end
end
