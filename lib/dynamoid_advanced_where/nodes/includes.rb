module DynamoidAdvancedWhere
  module Nodes
    class IncludesNode < BaseNode
      ALLOWED_VALUES = [
        String,
        Integer
      ].freeze

      ALLOWED_SET_TYPES = %i[
        string
        integer
      ].freeze

      class << self
        def validate_source_node(attr_config, value)
          unless ALLOWED_VALUES.include?(value.class)
            raise ArgumentError,
                  "Unable to do an include check against #{value.class}"
          end

          result = attr_config[:type] == :string || (
            attr_config[:type] == :set &&
            ALLOWED_SET_TYPES.include?(attr_config[:of])
          )

          result || raise(ArgumentError, 'Unable to perform includes on field')
        end
      end

      delegate :term, to: :term_node

      attr_accessor :term_node, :value

      def initialize(term_node:, value:, **args)
        super(args)

        self.term_node = term_node
        self.value = value
      end

      def to_condition_expression
        "contains(##{expression_prefix}, :#{expression_prefix}V)"
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
