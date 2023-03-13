# frozen_string_literal: true

require_relative './nodes/null_node'

module DynamoidAdvancedWhere
  class FilterBuilder
    VALID_COMPARETORS_FOR_RANGE_FILTER = [
      Nodes::GreaterThanNode
    ].freeze

    attr_accessor :expression_node, :klass

    def initialize(root_node:, klass:)
      self.expression_node = root_node.child_node
      self.klass = klass
    end

    def index_nodes
      [
        extract_query_filter_node,
        extract_range_key_node
      ].compact
    end

    def to_query_filter
      {
        key_condition_expression: key_condition_expression
      }.merge!(expression_filters)
    end

    def to_scan_filter
      expression_filters
    end

    def must_scan?
      !extract_query_filter_node.is_a?(Nodes::BaseNode)
    end

    private

    def key_condition_expression
      @key_condition_expression ||= [
        extract_query_filter_node,
        extract_range_key_node
      ].compact.map(&:to_expression).join(' AND ')
    end

    def expression_attribute_names
      [
        expression_node,
        *index_nodes
      ].map(&:expression_attribute_names).inject({}, &:merge!)
    end

    def expression_attribute_values
      [
        expression_node,
        *index_nodes
      ].map(&:expression_attribute_values).inject({}, &:merge!)
    end

    def expression_filters
      {
        filter_expression: expression_node.to_expression,
        expression_attribute_names: expression_attribute_names,
        expression_attribute_values: expression_attribute_values
      }.delete_if { |_, v| v.nil? || v.empty? }
    end

    def extract_query_filter_node
      @extract_query_filter_node ||=
        case expression_node
        when Nodes::EqualityNode
          node = expression_node
          if field_node_valid_for_key_filter(expression_node)
            self.expression_node = Nodes::NullNode.new
            node
          end
        when Nodes::AndNode
          id_filters = expression_node.child_nodes.select do |i|
            field_node_valid_for_key_filter(i)
          end

          if id_filters.length == 1
            self.expression_node = Nodes::AndNode.new(
              *(expression_node.child_nodes - id_filters)
            )

            id_filters.first
          end
        end
    end

    def field_node_valid_for_key_filter(node)
      node.is_a?(Nodes::EqualityNode) &&
        node.respond_to?(:lh_operation) &&
        node.lh_operation.is_a?(Nodes::FieldNode) &&
        node.lh_operation.field_path.length == 1 &&
        node.lh_operation.field_path[0].to_s == hash_key
    end

    def extract_range_key_node
      return unless extract_query_filter_node

      @extract_range_key_node ||=
        case expression_node
        when Nodes::AndNode
          id_filters = expression_node.child_nodes.select do |i|
            field_node_valid_for_range_filter(i)
          end

          if id_filters.length == 1
            self.expression_node = Nodes::AndNode.new(
              *(expression_node.child_nodes - id_filters)
            )

            id_filters.first
          end
        end
    end

    def field_node_valid_for_range_filter(node)
      node.respond_to?(:lh_operation) &&
        node.lh_operation.is_a?(Nodes::FieldNode) &&
        node.lh_operation.field_path.length == 1 &&
        node.lh_operation.field_path[0].to_s == range_key &&
        VALID_COMPARETORS_FOR_RANGE_FILTER.any? { |type| node.is_a?(type) }
    end

    def hash_key
      @hash_key ||= klass.hash_key.to_s
    end

    def range_key
      @range_key ||= klass.range_key.to_s
    end
  end
end
