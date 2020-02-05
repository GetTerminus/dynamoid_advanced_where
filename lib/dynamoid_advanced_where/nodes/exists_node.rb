# frozen_string_literal: true

require 'securerandom'

module DynamoidAdvancedWhere
  module Nodes
    class ExistsNode < BaseNode
      include Concerns::Negatable

      attr_accessor :field_node, :prefix
      def initialize(field_node:)
        self.field_node = field_node
        self.prefix = SecureRandom.hex
        freeze
      end

      def to_expression
        "NOT(
          attribute_not_exists(#{field_node.to_expression})
          or #{field_node.to_expression} = :#{prefix}
        )"
      end

      def expression_attribute_names
        field_node.expression_attribute_names
      end

      def expression_attribute_values
        {
          ":#{prefix}" => nil
        }
      end
    end

    module Concerns
      module SupportsExistance
        def exists?
          ExistsNode.new(field_node: self)
        end
        alias present? exists?
      end
    end
  end
end
