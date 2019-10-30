module DynamoidAdvancedWhere
  module Nodes
    class LessThanNode < BaseNode
      class << self
        def determine_subtype(attr_config, value)
          case attr_config[:type]
          when :number
            NumberAttr::LessThanNode
          when :datetime
            DatetimeAttr::LessThanNode
          when :date
            DateAttr::LessThanNode
          else
            raise ArgumentError, "Unable to perform less than on field of type #{attr_config[:type]}"
          end
        end
      end
    end
  end
end
