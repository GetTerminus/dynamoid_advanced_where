require 'spec_helper'

RSpec.describe "Start key results" do
  let(:large_string) { "a" * 400000 }
  let!(:item1) { klass.create(simple_string: 'baz', bar: '1', second_string: large_string) }
  let!(:item2) { klass.create(simple_string: 'foo', bar: '2', second_string: large_string) }
  let!(:item3) { klass.create(simple_string: 'baz', bar: '3', second_string: large_string) }
  let!(:item4) { klass.create(simple_string: 'foo', bar: '4', second_string: large_string) }
  let!(:item5) { klass.create(simple_string: 'baz', bar: '5', second_string: large_string) }
  let!(:item6) { klass.create(simple_string: 'baz', bar: '6', second_string: large_string) }

  describe "with only a hash key" do
    let(:klass) do
      new_class(table_name: 'and_check', table_opts: {key: :bar} ) do
        field :simple_string
        field :second_string
      end
    end

    it "returns all without a start key" do
      expect(
        klass.where{ (simple_string == 'baz') }.all
      ).to match_array [item1, item3, item5, item6]
    end

    it "returns from a start point" do
      expect(
        klass.where{ (simple_string == 'baz') }.start({bar: item1.bar }).all
      ).to match_array [item3, item5, item6]
    end

    it "handles nil start points" do
      expect(
        klass.where{ (simple_string == 'baz') }.start(nil).all
      ).to match_array [item1, item3, item5, item6]
    end
  end

  describe "with a hash and range key" do
    let(:klass) do
      new_class(table_name: 'and_check', table_opts: {key: :bar} ) do
        range :second_string
        field :simple_string
      end
    end

    it "returns all without a start key" do
      expect(
        klass.where{ (simple_string == 'baz') }.all
      ).to match_array [item1, item3, item5, item6]
    end

    it "returns from a start point" do
      first = klass.where { (simple_string == 'baz') }.all.first
      start_key = { bar: first.bar }
      expect(
        klass.where{ (simple_string == 'baz') }.start(start_key).all
      ).to eq [item3, item5, item6]
    end
  end
end