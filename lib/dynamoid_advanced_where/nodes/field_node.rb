# frozen_string_literal: true

require_relative './equality_node'
require_relative './greater_than_node'
require_relative './exists_node'
require_relative './includes'
require_relative './subfield'

module DynamoidAdvancedWhere
  module Nodes
    class FieldNode < BaseNode
      include Concerns::SupportsEquality
      include Concerns::SupportsExistance

      attr_accessor :field_path, :attr_prefix

      class << self
        def create_node(field_path:, attr_config:)
          specific_klass = FIELD_MAPPING.detect { |config, type| config <= attr_config }&.last

          raise ArgumentError, "unable to find field type for `#{attr_config}`" unless specific_klass

          specific_klass.new(field_path: field_path)
        end
      end

      def initialize(field_path:)
        self.field_path = field_path.is_a?(Array) ? field_path : [field_path]
        self.attr_prefix = SecureRandom.hex
        freeze
      end

      def to_expression
        field_path.collect.with_index do |_, i|
          "##{attr_prefix}#{i}"
        end.join('.')
      end

      def expression_attribute_names
        field_path.each_with_object({}).with_index do |(segment, hsh), i|
          hsh["##{attr_prefix}#{i}"] = segment
        end
      end

      def expression_attribute_values
        {}
      end
    end

    class StringAttributeNode < FieldNode
      include Concerns::SupportsIncludes
    end
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

    class NumericDateAttributeNode < FieldNode
      include Concerns::SupportsGreaterThan

      def parse_right_hand_side(val)
        if !val.is_a?(Date) || val.is_a?(DateTime)
          raise ArgumentError, "unable to compare date to type #{val.class}"
        end

        (val - Dynamoid::Persistence::UNIX_EPOCH_DATE).to_i
      end
    end

    class StringSetAttributeNode < FieldNode
      include Concerns::SupportsIncludes

      def parse_right_hand_side(val)
        raise ArgumentError, "unable to compare date to type #{val.class}" unless val.is_a?(String)

        val
      end
    end

    class IntegerSetAttributeNode < FieldNode
      include Concerns::SupportsIncludes

      def parse_right_hand_side(val)
        raise ArgumentError, "unable to compare date to type #{val.class}" unless val.is_a?(Integer)

        val
      end
    end

    class MapAttributeNode < FieldNode
      include Concerns::SupportsSubFields
    end

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
      { type: :datetime, store_as_string: false } => NumericDatetimeAttributeNode,
      { type: :datetime } => NumericDatetimeAttributeNode,

      # Date fields
      { type: :date, store_as_string: true } => nil,
      { type: :date, store_as_string: false } => NumericDateAttributeNode,
      { type: :date } => NumericDateAttributeNode,

      # Set Types
      { type: :set, of: :string } => StringSetAttributeNode,
      { type: :set, of: :integer } => IntegerSetAttributeNode,

      # Map Types
      { type: :map } => MapAttributeNode,
    }.freeze
  end
end
