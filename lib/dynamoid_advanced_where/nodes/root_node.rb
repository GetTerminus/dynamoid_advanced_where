# frozen_string_literal: true

module DynamoidAdvancedWhere
  module Nodes
    class RootNode < BaseNode
      attr_accessor :klass

      def initialize(klass:, &blk)
        self.klass = klass
        evaluate_block(blk) if blk
      end

      def evaluate_block(blk)
        child_blocks = if blk.arity.zero?
                         Dynamoid.logger.warn 'Using DynamoidAdvancedWhere builder without an argument is now deprecated'
                         instance_eval(&blk)
                       else
                         blk.call(self)
                       end

        self.child_nodes = [child_blocks].compact
      end

      def to_expression
        child_nodes.first.to_expression if child_nodes.length.positive?
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
