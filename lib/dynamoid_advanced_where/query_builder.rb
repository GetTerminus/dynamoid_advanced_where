require_relative './nodes'
require_relative './query_materializer'
require_relative './batched_updater'

module DynamoidAdvancedWhere
  class QueryBuilder
    attr_accessor :klass, :root_node

    delegate :all, to: :query_materializer
    delegate :combine_with!, to: :root_node

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

    def where(other_builder = nil, &blk)
      raise "cannot use a block and an argument" if other_builder && blk

      other_builder = self.class.new(klass: klass, &blk) if blk

      raise "passed argument must be a query builder" unless other_builder.is_a?(self.class)

      dup.tap{|q| q.combine_with!(other_builder.root_node, Nodes::AndNode) }
    end
    alias and where
    alias + where

    def dup
      self.class.new(klass: klass).tap{|b| b.root_node = root_node.dup }
    end
  end
end
