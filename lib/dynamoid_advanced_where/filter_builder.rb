# frozen_string_literal: true

module DynamoidAdvancedWhere
  class FilterBuilder
    VALID_COMPARETORS_FOR_RANGE_FILTER = [
      Nodes::GreaterThanNode
    ].freeze

    attr_accessor :query_builder, :klass

    delegate :root_node, to: :query_builder
    delegate :all_nodes, to: :root_node

    def initialize(query_builder:, klass:)
      self.query_builder = query_builder
      self.klass = klass
    end

    def index_nodes
      [
        extract_query_filter_node,
        extract_range_key_node
      ]
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

    def expression_filters
      {
        filter_expression: root_node.to_expression,
        expression_attribute_names: (all_nodes + index_nodes).compact.inject({}) do |hsh, i|
          hsh.merge!(i.expression_attribute_names)
        end,
        expression_attribute_values: (all_nodes + index_nodes).compact.inject({}) do |hsh, i|
          hsh.merge!(i.expression_attribute_values)
        end
      }.delete_if { |_, v| v.nil? || v.empty? }
    end

    def extract_query_filter_node
      @query_filter_node ||=
        case first_node
        when Nodes::EqualityNode
          if field_node_valid_for_key_filter(first_node)
            query_builder.root_node.child_nodes.delete_at(0)
          end
        when Nodes::AndNode
          hash_node_idx = first_node.child_nodes.index(&method(:field_node_valid_for_key_filter))
          first_node.child_nodes.delete_at(hash_node_idx) if hash_node_idx
        end
    end

    def field_node_valid_for_key_filter(node)
      node.is_a?(Nodes::EqualityNode) &&
        node.lh_operation.is_a?(Nodes::FieldNode) &&
        node.lh_operation.field_name.to_s == hash_key
    end

    def extract_range_key_node
      return unless extract_query_filter_node

      @range_key_node ||=
        case first_node
        when Nodes::AndNode
          hash_node_idx = first_node.child_nodes.index(&method(:field_node_valid_for_range_filter))
          first_node.child_nodes.delete_at(hash_node_idx) if hash_node_idx
        end
    end

    def field_node_valid_for_range_filter(node)
      node.lh_operation.is_a?(Nodes::FieldNode) &&
        node.lh_operation.field_name.to_s == range_key &&
        VALID_COMPARETORS_FOR_RANGE_FILTER.any? { |type| node.is_a?(type) }
    end

    def first_node
      query_builder.root_node.child_nodes.first
    end

    def hash_key
      @hash_key ||= query_builder.klass.hash_key.to_s
    end

    def range_key
      @range_key ||= query_builder.klass.range_key.to_s
    end
  end
end
