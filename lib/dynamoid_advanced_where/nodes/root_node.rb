# frozen_string_literal: true

require 'forwardable'
require_relative './null_node'

module DynamoidAdvancedWhere
  module Nodes
    class RootNode < BaseNode
      extend Forwardable
      attr_accessor :klass, :child_node

      def initialize(klass:, &blk)
        self.klass = klass
        evaluate_block(blk) if blk
        self.child_node ||= AndNode.new
        freeze
      end

      def method_missing(method, *args, &blk)
        if allowed_field?(method)
          FieldNode.create_node(attr_config: klass.attributes[method], field_path: method)
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

      private

      def evaluate_block(blk)
        self.child_node = if blk.arity.zero?
                            Dynamoid.logger.warn 'Using DynamoidAdvancedWhere builder without an argument is now deprecated'
                            instance_eval(&blk)
                          else
                            blk.call(self)
                          end
      end
    end
  end
end
