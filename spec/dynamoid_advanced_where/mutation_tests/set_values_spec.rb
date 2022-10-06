RSpec.describe 'Batch set_values' do
  let(:record) { klass.create(map_test: { foo: 0 }, custom_type: CustomType.new(4)) }

  let(:klass) do
    new_class(table_name: 'batch_value_setting') do
      field :simple_string
      field :string_datetime, :datetime, store_as_string: true
      field :standard_datetime, :datetime
      field :test_set, :set, of: :string
      field :test_arr, :array, of: :integer
      field :map_test, :map
      field :custom_type, CustomType
    end
  end

  it 'updates a string' do
    expect do
      klass.batch_update
           .set_values(simple_string: 'foobar')
           .apply(record.id)
    end.to change { record.reload.simple_string }.from(nil).to('foobar')
  end

  it 'updates a stringy date' do
    datetime = Time.at(Time.now.to_i)

    expect do
      klass.batch_update
           .set_values(string_datetime: datetime)
           .apply(record.id)
    end.to change { record.reload.string_datetime }.from(nil).to(datetime)
  end

  it 'updates a number date' do
    datetime = Time.at(Time.now.to_i)

    expect do
      klass.batch_update
           .set_values(standard_datetime: datetime)
           .apply(record.id)
    end.to change { record.reload.standard_datetime }.from(nil).to(datetime)
  end

  it 'updates a set' do
    expect do
      klass.batch_update
           .set_values(test_set: Set.new(%w[a b]))
           .apply(record.id)
    end.to change { record.reload.test_set }.from(nil).to(Set.new(%w[a b]))
  end

  it 'updates an array' do
    expect do
      klass.batch_update
           .set_values(test_set: %w[a b])
           .apply(record.id)
    end.to change { record.reload.test_set }.from(nil).to(%w[a b])
  end

  it 'updates a single item in a map' do
    expect do
      klass.batch_update
           .set_values(%i[map_test foo] => 42)
           .apply(record.id)
    end.to change { record.reload.map_test[:foo] }.from(0).to(42)
  end

  it 'updates the whole map' do
    expect do
      klass.batch_update
           .set_values(map_test: { foo: 42 })
           .apply(record.id)
    end.to change { record.reload.map_test[:foo] }.from(0).to(42)
  end

  it 'updates a single item in a custom type' do
    expect do
      klass.batch_update
           .set_values(%i[custom_type foo] => 42)
           .apply(record.id)
    end.to change { record.reload.custom_type.foo }.from(4).to(42)
  end

  it 'updates the whole map' do
    expect do
      klass.batch_update
           .set_values(custom_type: CustomType.new(42))
           .apply(record.id)
    end.to change { record.reload.custom_type.foo }.from(4).to(42)
  end
end
