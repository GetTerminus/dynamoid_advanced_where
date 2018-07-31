require 'spec_helper'

RSpec.describe "Basic value equality matching" do
  let(:klass) do
    new_class(table_name: 'equality_spec', table_opts: {key: :bar} ) do
      field :simple_string
      field :bool, :boolean
      field :native_bool, :boolean, store_as_native_boolean: true
    end
  end

  describe "boolean equality" do
    let!(:item1) { klass.create(bool: true) }
    let!(:item2) { klass.create(bool: false) }
    let!(:item3) { klass.create(bool: nil) }

    it "matches true" do
      expect(klass.where{ bool == true }.all).to match_array([item1])
    end

    it "matches true" do
      expect(klass.where{ bool == false }.all).to match_array([item2])
    end
  end

  describe "native boolean equality" do
    let!(:item1) { klass.create(native_bool: true) }
    let!(:item2) { klass.create(native_bool: false) }
    let!(:item3) { klass.create(native_bool: nil) }

    it "matches true" do
      expect(klass.where{ native_bool == true }.all).to match_array([item1])
    end

    it "matches true" do
      expect(klass.where{ native_bool == false }.all).to match_array([item2])
    end
  end


  describe "string equality" do
    let!(:item1) { klass.create(simple_string: 'foo') }
    let!(:item2) { klass.create(simple_string: 'bar') }

    it "matches string equals" do
     expect(
        klass.where{ simple_string == 'foo' }.all
      ).to match_array [item1]
    end

    it "matches string not equals" do
      expect(
        klass.where{ simple_string != 'foo' }.all
      ).to match_array [item2]
    end
  end
end
