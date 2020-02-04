# frozen_string_literal: true

require_relative './equality_node'
require_relative './greater_than_node'

module DynamoidAdvancedWhere
  module Nodes

    class FieldNode < BaseNode
      include Concerns::SupportsEquality

      attr_accessor :klass, :field_name, :attr_prefix

      class << self
        def create_node(klass:, field_name:)
          attr_config = klass.attributes[field_name]
          specific_klass = FIELD_MAPPING.detect { |config, type| config <= attr_config }&.last

          raise ArgumentError, "unable to find field type for `#{attr_config}`" unless specific_klass

          specific_klass.new(field_name: field_name, klass: klass)
        end
      end

      def initialize(field_name:, klass:)
        self.field_name = field_name
        self.klass = klass
        self.attr_prefix = SecureRandom.hex
      end

      def dup
        self.class.new(field_name: field_name, klass: klass).tap do |e|
          e.child_nodes = dup_children
        end
      end

      def to_expression
        "##{attr_prefix} "
      end

      def expression_attribute_names
        { "##{attr_prefix}" => field_name }
      end

      def expression_attribute_values
        {}
      end

      def attr_config
        klass.attributes[field_name]
      end
    end

    class StringAttributeNode < FieldNode; end
    class NativeBooleanAttributeNode < FieldNode; end

    class StringBooleanAttributeNode < FieldNode
      def parse_right_hand_side(val)
        val ? 't' : 'f'
      end
    end

    class NumberAttributeNode < FieldNode
      include Concerns::SupportsGreaterThan

      ALLOWED_COMPARISON_TYPES = [
        Numeric
      ].freeze

      def parse_right_hand_side(val)
        unless ALLOWED_COMPARISON_TYPES.detect { |k| val.is_a?(k) }
          raise ArgumentError, "unable to compare number to `#{val.class}`"
        end

        val
      end
    end

    class NumericDatetimeAttributeNode < FieldNode
      include Concerns::SupportsGreaterThan

      def parse_right_hand_side(val)
        if val.is_a?(Date)
          val.to_time.to_i
        elsif val.is_a?(Time)
          val.to_f
        else
          raise ArgumentError, "unable to compare datetime to type #{val.class}"
        end
      end
    end

    class NumericDateAttributeNode < NumericDatetimeAttributeNode; end

    FIELD_MAPPING = {
      { type: :string } => StringAttributeNode,
      { type: :number } => NumberAttributeNode,

      # Boolean Fields
      { type: :boolean, store_as_native_boolean: true } =>
        NativeBooleanAttributeNode,
      { type: :boolean, store_as_native_boolean: false } =>
        StringBooleanAttributeNode,

      # Datetime fields
      { type: :datetime, store_as_string: true } => nil,
      { type: :datetime, store_as_string: false } => NumericDateAttributeNode,
      { type: :datetime } => NumericDateAttributeNode,

      # Date fields
      { type: :date, store_as_string: true } => nil,
      { type: :date, store_as_string: false } => NumericDateAttributeNode,
      { type: :date } => NumericDateAttributeNode,
    }.freeze
  end
end
