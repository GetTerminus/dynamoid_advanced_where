require 'spec_helper'

RSpec.describe "Record limits" do
  let(:large_string) { "a" * 400000 }
  let!(:item1) { klass.create(simple_string: 'baz', bar: '1', second_string: large_string) }
  let!(:item2) { klass.create(simple_string: 'foo', bar: '2', second_string: large_string) }
  let!(:item3) { klass.create(simple_string: 'baz', bar: '3', second_string: large_string) }
  let!(:item4) { klass.create(simple_string: 'foo', bar: '4', second_string: large_string) }
  let!(:item5) { klass.create(simple_string: 'baz', bar: '5', second_string: large_string) }
  let!(:item6) { klass.create(simple_string: 'baz', bar: '6', second_string: large_string) }

  describe "when scanning" do
    let(:klass) do
      new_class(table_name: 'and_check', table_opts: {key: :bar} ) do
        field :simple_string
        field :second_string
      end
    end

    it "limits the returned records" do
      expect(
        klass.where{ (simple_string == 'baz') }.limit(2).to_a.length
      ).to eq 2
    end
  end

  describe "when querying" do
    let(:klass) do
      new_class(table_name: 'and_check', table_opts: {key: :simple_string} ) do
        range :bar
        field :simple_string
        field :second_string
      end
    end

    it "limits the returned records" do
      expect(
        klass.where{ (simple_string == 'baz') }.limit(2).to_a.length
      ).to eq 2
    end
  end
end
