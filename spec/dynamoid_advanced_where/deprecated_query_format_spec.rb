require 'spec_helper'

RSpec.describe "deprecated where block format" do
  let(:klass) do
    new_class(table_name: "deprecated_query_format", table_opts: {key: :bar} ) do
      field :simple_string
    end
  end

  describe "string equality" do
    let!(:item1) { klass.create(simple_string: 'foo') }
    let!(:item2) { klass.create(simple_string: 'bar') }

    it "works without a param" do
     expect(
        klass.where{ simple_string == 'foo' }.all
      ).to match_array [item1]
    end

    it "works with a param" do
      expect(
        klass.where{|r| r.simple_string != 'foo' }.all
      ).to match_array [item2]
    end
  end
end
