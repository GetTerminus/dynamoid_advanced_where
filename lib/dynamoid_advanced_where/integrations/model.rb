# frozen_string_literal: true

require 'dynamoid_advanced_where/query_builder'

module DynamoidAdvancedWhere
  # Allows classes to be queried by where, all, first, and each and return criteria chains.
  module Integrations
    module Model
      extend ActiveSupport::Concern

      class_methods do
        def advanced_where(&blk)
          DynamoidAdvancedWhere::QueryBuilder.new(klass: self, &blk)
        end

        def batch_update
          advanced_where {}.batch_update
        end

        def where(*args, &blk)
          if !args.empty?
            raise ArgumentError, 'You may not specify where arguments and block' if blk

            super(*args)
          else
            DynamoidAdvancedWhere::QueryBuilder.new(klass: self, &blk)
          end
        end
      end
    end
  end
end

Dynamoid::Document.include DynamoidAdvancedWhere::Integrations::Model
