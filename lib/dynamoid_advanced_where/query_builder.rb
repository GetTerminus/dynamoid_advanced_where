require_relative './nodes'
require_relative './query_materializer'
require_relative './batched_updater'

module DynamoidAdvancedWhere
  class QueryBuilder
    attr_accessor :klass, :root_node, :start_hash

    delegate :all, :each, to: :query_materializer

    def initialize(klass:, start_hash: nil, root_node: nil, &blk)
      self.klass = klass
      self.root_node = root_node || Nodes::RootNode.new(klass: klass, &blk)
      self.start_hash = start_hash

      freeze
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
      raise 'cannot use a block and an argument' if other_builder && blk

      other_builder = self.class.new(klass: klass, &blk) if blk

      raise 'passed argument must be a query builder' unless other_builder.is_a?(self.class)

      local_root_node = root_node
      self.class.new(klass: klass) do
        Nodes::AndNode.new(
          other_builder.root_node.child_node,
          local_root_node.child_node
        )
      end
    end
    alias and where

    def start(key_hash)
      return self if key_hash.nil? || key_hash.empty?

      self.class.new(klass: klass, start_hash: key_hash, root_node: root_node)
    end
  end
end
