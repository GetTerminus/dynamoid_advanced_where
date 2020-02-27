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

    it "returns from a start point" do
      expect(
        klass.where{ (simple_string == 'baz') }.start({bar: item1.bar }).all
      ).to match_array [item3]
    end
  end

  describe "with a hash and range key" do
    let(:klass) do
      new_class(table_name: 'and_check', table_opts: {key: :bar} ) do
        range :second_string
        field :simple_string
      end
    end

    let!(:item0) { 4.times { |i| klass.create(simple_string: 'foo', bar: "junk#{i}", second_string: 'a') } }
    let!(:item1) { klass.create(simple_string: 'baz', bar: '1', second_string: 'x') }
    let!(:item2) { klass.create(simple_string: 'foo', bar: '2', second_string: 'y') }
    let!(:item3) { klass.create(simple_string: 'baz', bar: '3', second_string: 'z') }

    it "returns all on all" do
      expect(
        klass.where{ (simple_string == 'baz') }.all
      ).to match_array [item1, item3]
    end

    it "limits with start" do
      start_key = { bar: item1.bar }
      expect(
        klass.where{ (simple_string == 'baz') }.start(start_key).all
      ).to match_array [item3]
    end
  end
end