require 'spec_helper'

RSpec.describe "Paginated results" do

  describe "with only a hash key" do
    let(:klass) do
      new_class(table_name: 'and_check', table_opts: {key: :bar} ) do
        field :simple_string
        field :second_string
      end
    end

    let!(:item1) { klass.create(simple_string: 'baz', bar: '1') }
    let!(:item2) { klass.create(simple_string: 'foo', bar: '2') }
    let!(:item3) { klass.create(simple_string: 'baz', bar: '3') }

    it "returns all on all" do
      expect(
        klass.where{ (simple_string == 'baz') }.all
      ).to match_array [item1, item3]
    end

    it "limits" do
      result = klass.where{ (simple_string == 'baz') }.record_limit(1).next_page
      expect(result.last_evaluated_key).to eq({'bar' => '1'})
      expect(result).to eq([item1])
    end

    it "limits from a start point" do
      expect(
        klass.where{ (simple_string == 'baz') }.start({bar: item1.bar }).record_limit(1).next_page
      ).to match_array [item3]
    end

    it "returns nil on last page" do
      result = klass.where{ (simple_string == 'baz') }.start({bar: item1.bar }).record_limit(5).next_page
      expect(result).to match_array [item3]
      expect(result.last_evaluated_key).to be_nil
    end
  end

  describe "with a hash and range key" do
    let(:klass) do
      new_class(table_name: 'and_check', table_opts: {key: :bar} ) do
        range :second_string
        field :simple_string
      end
    end

    let!(:item1) { klass.create(simple_string: 'baz', bar: '1', second_string: 'x') }
    let!(:item2) { klass.create(simple_string: 'foo', bar: '2', second_string: 'y') }
    let!(:item3) { klass.create(simple_string: 'baz', bar: '3', second_string: 'z') }

    it "returns all on all" do
      expect(
        klass.where{ (simple_string == 'baz') }.all
      ).to match_array [item1, item3]
    end

    it "limits" do
      result = klass.where{ (simple_string == 'baz') }.record_limit(1).next_page
      expect(result.last_evaluated_key).to eq({'bar' => item1.bar})
      expect(result).to eq([item1])
    end

    it "limits with start" do
      start_key = klass.where{ (simple_string == 'baz') }.record_limit(1).next_page.last_evaluated_key
      expect(
        klass.where{ (simple_string == 'baz') }.start(start_key).record_limit(1)
      ).to match_array [item3]
    end
  end
end