
RSpec.describe "increment batch" do
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
        .increment(:numb_a)
        .apply(id, 'a')
      }.to change {
        record1.reload.numb_a
      }.from(0).to(1)
    end

  end

  context "with only a hash key" do
    let!(:record1) { klass.create(id: id,  numb_a: 0, numb_b: 0, map_test: { foo: 0}, custom_type: CustomType.new(2)) }
    let!(:record2) { klass.create(id: id2) }

    class CustomType
      attr_accessor :foo
      def initialize(f); self.foo = f; end

      def dynamoid_dump
        { "foo": foo }
      end

      def self.dynamoid_load(content)
        new(content["foo"])
      end
    end

    let(:klass) do
      new_class(table_name: 'inc_and_dec_batch_test') do
        field :numb_a, :number
        field :numb_b, :integer
        field :map_test, :map
        field :custom_type, CustomType
      end
    end

    it "increments a value" do
      expect {
        klass
          .batch_update
          .increment(:numb_a, :numb_b)
          .apply(id)
      }.to change {
        record1.reload.attributes.slice(:numb_a, :numb_b).values
      }.from([0, 0]).to([1, 1])
    end

    it "increments a value by a configurable amount" do
      expect {
        klass
          .batch_update
          .increment(:numb_a, :numb_b, by: 5)
          .apply(id)
      }.to change {
        record1.reload.attributes.slice(:numb_a, :numb_b).values
      }.from([0, 0]).to([5, 5])
    end


    it "increments from nil" do
      expect {
        klass
          .batch_update
          .increment(:numb_a, :numb_b, by: 5)
          .apply(id2)
      }.to change {
        record2.reload.attributes.slice(:numb_a, :numb_b).values
      }.to([5, 5])
    end

    it "increments from a map" do
      expect {
        klass
          .batch_update
          .increment([:map_test, :foo], by: 5)
          .apply(id)
      }.to change {
          record1.reload.map_test[:foo]
        }.to(5)
    end

    it "increments from a custom type" do
      expect {
        klass
          .batch_update
          .increment([:custom_type, :foo], by: 5)
          .apply(id)
      }.to change {
          record1.reload.custom_type.foo
        }.to(7)
    end
  end
end
