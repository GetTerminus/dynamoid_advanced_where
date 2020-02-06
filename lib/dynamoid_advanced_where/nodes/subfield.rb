# frozen_string_literal: true

module DynamoidAdvancedWhere
  module Nodes
    module Concerns
      module SupportsSubFields
        def sub_field(*path, options)
          Nodes::FieldNode.create_node(
            field_path: field_path + path,
            attr_config: options
          )
        end
        alias dig sub_field
      end
    end
  end
end
