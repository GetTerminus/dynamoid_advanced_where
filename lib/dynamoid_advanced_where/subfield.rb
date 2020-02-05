# frozen_string_literal: true

require_relative './nodes/greater_than_node'

module DynamoidAdvancedWhere
  class SubField
    include Nodes::Concerns::SupportsGreaterThan
		include Concerns::SupportsEquality
    attr_accessor :path, :options, :attr_prefix

    def initialize(path:, options:)
      raise "no type set for sub_field #{args}" unless options[:type]

      self.path = path.freeze
      self.options = options.freeze
      self.attr_prefix = SecureRandom.hex
    end

    def to_expression
      @expression = path.collect.with_index do |_, i|
        "##{attr_prefix}#{i}"
      end.join('.')
    end

    def expression_attribute_names
      path.each_with_object({}).with_index do |(segment, hsh), i|
        hsh["##{attr_prefix}#{i}"] = segment
      end
    end

    def expression_attribute_values
      {}
    end
  end

  module Nodes
    module Concerns
      module SupportsSubFields
        def sub_field(*path, options)
          SubField.new(path: [field_name] + path, options: options)
        end
        alias dig sub_field
      end
    end
  end
end
