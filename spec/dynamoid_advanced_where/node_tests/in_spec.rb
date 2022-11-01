require 'spec_helper'

RSpec.describe "Inclusion " do
  let(:klass) do
    new_class(table_name: "equality_spec", table_opts: {key: :bar} ) do
      range :range_str
      field :simple_string
      field :bool, :boolean, store_as_native_boolean: false
      field :native_bool, :boolean, store_as_native_boolean: true
    end
  end

  describe "using the .in?" do
    let!(:item1) { klass.create(simple_string: 'foo', range_str: 'foo', bool: true) }
    let!(:item2) { klass.create(simple_string: 'foo', range_str: 'bar', bool: false) }

    it "matches string inclusion" do
     expect(
       klass.where{ (simple_string == 'foo') & range_str.in?(%w[omg foo]) }.all
      ).to match_array [item1]
    end
  end
end
