require 'spec_helper'

RSpec.describe "Negation " do
  let(:klass) do
    new_class(table_name: "equality_spec", table_opts: {key: :bar} ) do
      field :simple_string
      field :bool, :boolean, store_as_native_boolean: false
      field :native_bool, :boolean, store_as_native_boolean: true
    end
  end

  describe "chaining negation" do
    let!(:item1) { klass.create(simple_string: 'foo', bool: true) }
    let!(:item2) { klass.create(simple_string: 'bar', bool: false) }

    it "matches string equals" do
     expect(
        klass.where{ !(simple_string == 'asdf') & (bool == true)}.all
      ).to match_array [item1]
    end

    it "matches string not equals" do
      expect(
        klass.where{ !(simple_string == 'foo') | (bool == false)}.all
      ).to match_array [item2]
    end
  end
end
