RSpec.describe 'Upserting' do
  let(:id) { SecureRandom.uuid }

  context 'with a hash and range key' do
    let(:klass) do
      new_class(table_name: 'appending_with_range_test') do
        field :simple_string
        field :numb_a, :number
        field :test_set, :set, of: :string
        field :test_arr, :array, of: :integer

        self.range_key = :numb_a
      end
    end

    it "performs the 'sert' side of upsert append" do
      expect(
        klass
          .batch_update
          .set_values(simple_string: 'hi')
          .append_to(test_set: %w[foo bar], test_arr: [1, 1, 2, 3])
          .apply('foo', 123)
      ).to be_a_kind_of(klass).and have_attributes(
        id: 'foo',
        numb_a: 123,
        simple_string: 'hi',
        test_set: Set.new(%w[foo bar]),
        test_arr: [1, 1, 2, 3]
      )
    end
  end

  context 'with only a hash key' do
    let(:klass) do
      new_class(table_name: 'appending_without_range_test') do
        field :simple_string
        field :test_set, :set, of: :string
        field :test_arr, :array, of: :integer
      end
    end

    it "performs the 'sert' side of upsert append" do
      expect(
        klass
          .batch_update
          .set_values(simple_string: 'hi')
          .append_to(test_set: %w[foo bar], test_arr: [1, 1, 2, 3])
          .apply('foo')
      ).to be_a_kind_of(klass).and have_attributes(
        id: 'foo',
        simple_string: 'hi',
        test_set: Set.new(%w[foo bar]),
        test_arr: [1, 1, 2, 3]
      )
    end

    context 'when modifying an existing item' do
      let!(:instance) do
        klass.create(simple_string: 'foo', test_set: ['abc'], test_arr: [9])
      end

      it 'updates that item' do
        expect(
          klass.batch_update.append_to(
            test_set: ['def'],
            test_arr: [1],
          ).apply(instance.id)
        ).to have_attributes(
          test_set: Set.new(%w[abc def]),
          test_arr: [9, 1]
        )
      end

      it 'performs the update conditionally' do
        expect(
          klass.where { simple_string != 'foo' }.batch_update.append_to(
            test_set: ['def'],
            test_arr: [1],
          ).apply(instance.id)
        ).to be_nil
      end
    end
  end
end
