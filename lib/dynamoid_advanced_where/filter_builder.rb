# frozen_string_literal: true

require_relative './nodes/null_node'

module DynamoidAdvancedWhere
  class FilterBuilder
    VALID_COMPARETORS_FOR_RANGE_FILTER = [
      Nodes::GreaterThanNode,
    ].freeze

    attr_accessor :expression_node, :query_filter_node, :range_key_node, :klass

    def initialize(root_node:, klass:)
      node = root_node.child_node
      self.expression_node = node.is_a?(Nodes::AndNode) ? node : Nodes::AndNode.new(node)
      self.klass = klass
    end

    def index_nodes
      [
        query_filter_node,
        range_key_node,
      ].compact
    end

    def to_query_filter
      {
        key_condition_expression: key_condition_expression,
      }.merge!(expression_filters)
    end

    def to_scan_filter
      expression_filters
    end

    def set_node_for_range_key(node)
      raise "node not found in expression" unless expression_node.child_nodes.include?(node)

      self.range_key_node = node

      self.expression_node = Nodes::AndNode.new(
        *(expression_node.child_nodes - [node])
      )
    end

    def set_node_for_query_filter(node)
      raise "node not found in expression" unless expression_node.child_nodes.include?(node)

      self.query_filter_node = node

      self.expression_node = Nodes::AndNode.new(
        *(expression_node.child_nodes - [node])
      )
    end

    # Returns a hash of the field name and the node that filters on it
    def extractable_fields_for_hash_and_range
      expression_node.child_nodes.each_with_object({}) do |node, hash|
        next unless node.respond_to?(:lh_operation) &&
                      node.lh_operation.is_a?(Nodes::FieldNode) &&
                      node.lh_operation.field_path.length == 1

        hash[node.lh_operation.field_path[0].to_s] = node
      end
    end

    private

    def key_condition_expression
      @key_condition_expression ||= [
        query_filter_node,
        range_key_node,
      ].compact.map(&:to_expression).join(' AND ')
    end

    def expression_attribute_names
      [
        expression_node,
        *index_nodes,
      ].map(&:expression_attribute_names).inject({}, &:merge!)
    end

    def expression_attribute_values
      [
        expression_node,
        *index_nodes,
      ].map(&:expression_attribute_values).inject({}, &:merge!)
    end

    def expression_filters
      {
        filter_expression: expression_node.to_expression,
        expression_attribute_names: expression_attribute_names,
        expression_attribute_values: expression_attribute_values,
      }.delete_if { |_, v| v.nil? || v.empty? }
    end
  end
end
