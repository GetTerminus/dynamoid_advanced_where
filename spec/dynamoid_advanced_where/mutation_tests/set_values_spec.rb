
RSpec.describe "Batch set_values" do
  let(:record) { klass.create }

  let(:klass) do
    new_class(table_name: 'batch_value_setting') do
      field :simple_string
      field :string_datetime, :datetime, store_as_string: true
      field :standard_datetime, :datetime
      field :test_set, :set, of: :strings
      field :test_arr, :array, of: :integers
    end
  end


  it "updates a string" do
    expect {
      klass.batch_update
        .set_values(simple_string: 'foobar')
        .apply(record.id)
    }.to change{ record.reload.simple_string }.from(nil).to('foobar')
  end

  it "updates a stringy date" do
    datetime = Time.at(Time.now.to_i)

    expect {
      klass.batch_update
        .set_values(string_datetime: datetime)
        .apply(record.id)
    }.to change{ record.reload.string_datetime}.from(nil).to(datetime)
  end

  it "updates a number date" do
    datetime = Time.at(Time.now.to_i)

    expect {
      klass.batch_update
        .set_values(standard_datetime: datetime)
        .apply(record.id)
    }.to change{ record.reload.standard_datetime}.from(nil).to(datetime)
  end

  it "updates a set" do
    expect {
      klass.batch_update
        .set_values(test_set: Set.new(['a', 'b']))
        .apply(record.id)
    }.to change{ record.reload.test_set}.from(nil).to(Set.new(['a', 'b']))
  end

  it "updates an array" do
    expect {
      klass.batch_update
        .set_values(test_set: ['a', 'b'])
        .apply(record.id)
    }.to change{ record.reload.test_set}.from(nil).to(['a', 'b'])
  end
end
