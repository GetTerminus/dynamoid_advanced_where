module ClassCreator
  def new_class(table_name: SecureRandom.uuid.tr('-',''), table_opts: {}, &blk)
    klass = Class.new do
      include Dynamoid::Document
      table({ name: (table_name || :documents) }.merge(table_opts))
    end
    klass.class_eval(&blk) if block_given?
    klass.create_table
    klass
  end
end
