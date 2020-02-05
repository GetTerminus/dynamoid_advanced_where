# frozen_string_literal: true

require 'forwardable'
require_relative './null_node'

module DynamoidAdvancedWhere
  module Nodes
    class RootNode < BaseNode
      extend Forwardable
      attr_accessor :klass, :child_node

      #def_delegators :@child_node,
      #               :expression_attribute_names,
      #               :expression_attribute_values,
      #               :to_expression

      def initialize(klass:, &blk)
        self.klass = klass
        evaluate_block(blk) if blk
        self.child_node ||= NullNode.new
        freeze
      end

      def evaluate_block(blk)
        self.child_node = instance_eval(&blk)
      end

      def method_missing(method, *args, &blk)
        if allowed_field?(method)
          FieldNode.create_node(klass: klass, field_name: method)
        else
          super
        end
      end

      def respond_to_missing?(method, _i)
        allowed_field?(method)
      end

      def allowed_field?(method)
        klass.attributes.key?(method.to_sym)
      end
    end
  end
end
