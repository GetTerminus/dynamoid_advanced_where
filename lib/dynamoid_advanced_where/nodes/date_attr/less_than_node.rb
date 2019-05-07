module DynamoidAdvancedWhere
  module Nodes
    module DateAttr
      class LessThanNode < BaseNode
        delegate :term, to: :term_node

        attr_accessor :term_node, :value

        def initialize(term_node: , value: , **args)
          super(args)
          self.term_node = term_node

          if !value.is_a?(Date) || value.is_a?(DateTime)
            raise ArgumentError, "Unable to perform less than on date with a value of type #{value.class}. Expected Date"
          end

          if attribute_config[:store_as_string]
            raise ArgumentError, 'Unable to perform less than on value of type Date unless stored as an integer'
          end

          self.value = (value - Dynamoid::Persistence::UNIX_EPOCH_DATE).to_i
        end

        def to_condition_expression
          "##{expression_prefix} < :#{expression_prefix}V"
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

        def build_dup
          self.class.new(term_node: term_node, value: value, klass: klass)
        end
      end
    end
  end
end
