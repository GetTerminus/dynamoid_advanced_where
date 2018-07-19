RSpec.describe "Upserting" do
  let(:id) { SecureRandom.uuid }

  context "with only a hash key" do
    let(:klass) do
      new_class(table_name: 'upsert_without_range_test') do
        field :simple_string
        field :numb, :number
        field :string_date, :datetime, store_as_string: true
        field :int_date, :datetime
      end
    end

    it "performs the 'sert' side of upsert" do
      expect(
        klass.where{ !simple_string }.upsert(
          id,
          simple_string: 'hi',
          string_date: 1.day.ago,
          int_date: 1.day.ago,
        )
      ).to be_a_kind_of(klass).and have_attributes(simple_string: 'hi')
    end


    context "updating a record" do
      let!(:item1) { klass.create(numb: 4, simple_string: 'foo') }

      it "performs the conditional update" do
        expect{
          klass.where{ numb > 2 }.upsert(
            item1.id,
            simple_string: 'hi',
          )
        }.to change {
          item1.reload.simple_string
        }.from('foo').to('hi')
      end

      it "returns nil if the update was unsuccessful" do
        expect(
          klass.where{ numb > 4 }.upsert(item1.id, simple_string: 'hi')
        ).to be_nil
      end

      it "updates the item's value" do
        expect{
          klass.where{ numb > 4 }.upsert(item1.id, simple_string: 'hi')
        }.not_to change {
          item1.reload.simple_string
        }.from('foo')
      end
    end
  end


  context "with a hash and a range key" do
    let(:klass) do
      new_class(table_name: 'upsert_with_range_test') do
        field :simple_string
        field :numb, :number
        field :numb_a, :number

        self.range_key = :numb_a
      end
    end

    it "performs the 'sert' side of upsert" do
      expect(
        klass.where{ !simple_string }.upsert(id, 5, simple_string: 'hi')
      ).to be_a_kind_of(klass).and have_attributes(numb_a: 5, simple_string: 'hi')
    end


    context "updating a record" do
      let!(:item1) { klass.create(numb_a: 7, numb: 4, simple_string: 'foo') }

      it "performs the conditional update" do
        expect{
          klass.where{ numb > 2 }.upsert(item1.id, 7, simple_string: 'hi')
        }.to change {
          item1.reload.simple_string
        }.from('foo').to('hi')
      end

      it "returns nil if the update was unsuccessful" do
        expect(
          klass.where{ numb > 4 }.upsert(item1.id, 7, simple_string: 'hi')
        ).to be_nil
      end

      it "updates the item's value" do
        expect{
          klass.where{ numb > 4 }.upsert(item1.id, 7, simple_string: 'hi')
        }.not_to change {
          item1.reload.simple_string
        }.from('foo')
      end
    end
  end
end
