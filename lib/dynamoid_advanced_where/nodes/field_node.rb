# frozen_string_literal: true

require_relative './equality_node'

module DynamoidAdvancedWhere
  module Nodes

    class FieldNode < BaseNode
      include Concerns::SupportsEquality

      attr_accessor :klass, :field_name, :attr_prefix

      class << self
        def create_node(klass:, field_name:)
          attr_config = klass.attributes[field_name]
          specific_klass = FIELD_MAPPING.detect { |config, type| config <= attr_config }&.last

          raise "unable to find field type for `#{attr_config}`" unless specific_klass

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

    FIELD_MAPPING = {
      { type: :string } => StringAttributeNode,
      { type: :boolean, store_as_native_boolean: true } => NativeBooleanAttributeNode,
      { type: :boolean, store_as_native_boolean: false } => StringBooleanAttributeNode,
    }.freeze

  end
end
