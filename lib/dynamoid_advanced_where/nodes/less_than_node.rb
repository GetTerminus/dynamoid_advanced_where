module DynamoidAdvancedWhere
  module Nodes
    class LessThanNode < BaseNode
      delegate :term, to: :term_node

      attr_accessor :term_node, :value

      def initialize(term_node: , value: , **args)
        super(args)
        self.term_node = term_node
        self.value = case value
                     when Numeric
                       value
                     when Date
                       value.to_time.to_i
                     when Time
                       value.to_f
                     end
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

      class << self
        def determine_subtype(attr_config, value)
          # Validate field Type
          unless attr_config[:type].in?(%i[number datetime])
            raise ArgumentError, "Unable to perform less than on field of type #{attr_config[:type]}"
          end

          if attr_config[:type] == :datetime && attr_config[:store_as_string]
            raise ArgumentError, 'Unable to perform less than on value of type Datetime unless stored as an integer'
          end

          case attr_config[:type]
          when :number
            if !value.is_a?(Numeric)
              raise ArgumentError, "Unable to perform less than on value of type #{value.class}"
            end
          when :datetime
            if !value.is_a?(Date) && !value.is_a?(Time)
              raise ArgumentError, "Unable to perform less than on datetime with a value of type #{value.class}. Expected Date or Time"
            end
          end

          self
        end
      end
    end
  end
end
