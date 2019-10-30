
RSpec.describe "decrement batch" do
  let(:id)  { SecureRandom.uuid }
  let(:id2) { SecureRandom.uuid }

  context "with a hash and range key" do
    let!(:record1) { klass.create(id: id, foo: 'a', numb_a: 0) }
    let!(:record2) { klass.create(id: id, foo: 'b', numb_a: 0) }

    let(:klass) do
      new_class(table_name: 'inc_and_dec_batch_test_with_range') do
        field :numb_a, :number
        field :numb_b, :integer
        field :foo, :string

        self.range_key = :foo
      end
    end

    it "is properly limited to a single range key" do
      expect {
        klass
        .batch_update
        .decrement(:numb_a)
        .apply(id, 'a')
      }.to change {
        record1.reload.numb_a
      }.from(0).to(-1)
    end

  end

  context "with only a hash key" do
    let!(:record1) { klass.create(id: id,  numb_a: 0, numb_b: 0) }
    let!(:record2) { klass.create(id: id2) }

    let(:klass) do
      new_class(table_name: 'inc_and_dec_batch_test') do
        field :numb_a, :number
        field :numb_b, :integer
      end
    end

    it "decrements a value" do
      expect {
        klass
          .batch_update
          .decrement(:numb_a, :numb_b)
          .apply(id)
      }.to change {
        record1.reload.attributes.slice(:numb_a, :numb_b).values
      }.from([0, 0]).to([-1, -1])
    end

    it "decrements a value by a configurable amount" do
      expect {
        klass
          .batch_update
          .decrement(:numb_a, :numb_b, by: 5)
          .apply(id)
      }.to change {
        record1.reload.attributes.slice(:numb_a, :numb_b).values
      }.from([0, 0]).to([-5, -5])
    end


    it "decrements from nil" do
      expect {
        klass
          .batch_update
          .decrement(:numb_a, :numb_b, by: 5)
          .apply(id2)
      }.to change {
        record2.reload.attributes.slice(:numb_a, :numb_b).values
      }.from([nil, nil]).to([-5, -5])
    end
  end
end
