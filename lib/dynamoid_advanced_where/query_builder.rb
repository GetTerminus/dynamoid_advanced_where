require_relative './nodes'
require_relative './query_materializer'
require_relative './batched_updater'

module DynamoidAdvancedWhere
  class QueryBuilder
    attr_accessor :klass, :root_node

    delegate :all, to: :query_materializer

    def initialize(klass:, &blk)
      self.klass = klass
      self.root_node = Nodes::RootNode.new(klass: klass, &blk)
    end

    def query_materializer
      QueryMaterializer.new(query_builder: self)
    end

    def batch_update
      BatchedUpdater.new(query_builder: self)
    end

    def upsert(*args)
      update_fields = args.extract_options!
      batch_update.set_values(update_fields).apply(*args)
    end
  end
end
