require 'spec_helper'

RSpec.describe "Projecting fields" do
  let!(:item1) { klass.create(simple_string: 'baz', bar: '1', second_string: 'abcd') }

  describe "when scanning" do
    let(:klass) do
      new_class(table_name: 'and_check', table_opts: {key: :bar} ) do
        field :simple_string
        field :second_string
      end
    end

    it "limits the fields" do
      item = klass.where{ (simple_string == 'baz') }.project(:simple_string, :bar).to_a.first.attributes
      expect(item).to include(simple_string: 'baz', bar: '1')
      expect(item).not_to include(:second_string)
    end
  end

  describe "when querying" do
    let(:klass) do
      new_class(table_name: 'and_check_record_limit', table_opts: {key: :simple_string} ) do
        range :bar
        field :simple_string
        field :second_string
      end
    end

    it "limits the returned records" do
      item = klass.where{ (simple_string == 'baz') }.project(:simple_string, :bar).to_a.first.attributes
      expect(item).to include(simple_string: 'baz', bar: '1')
      expect(item).not_to include(:second_string)
    end
  end
end
