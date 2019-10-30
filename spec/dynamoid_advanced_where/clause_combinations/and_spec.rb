require 'spec_helper'

RSpec.describe "Combining multiple queries with &" do
  let(:klass) do
    new_class(table_name: 'combination_and_check', table_opts: {key: :bar} ) do
      field :simple_string
      field :second_string
    end
  end

  let!(:instance1) { klass.create(simple_string: 'a', second_string: 'b') }
  let!(:instance2) { klass.create(simple_string: 'a', second_string: 'c') }
  let!(:instance3) { klass.create(simple_string: 'a', second_string: 'd') }
  let!(:instance4) { klass.create(simple_string: 'a') }

  let!(:base_filter) { klass.where{ simple_string == 'a' } }

  after do
    # It should not modify the initial filter
    expect(base_filter.all).to match_array [instance1, instance2, instance3, instance4]
  end

  context "when passing an argument and a block" do
    it "raises an error" do
      expect{
        base_filter.where(base_filter){ second_string == 'b' }.all
      }.to raise_error(/cannot use a block and an argument/)
    end
  end

  context "when sending a block" do
    it "allows combinations with .where" do
      expect(
        base_filter.where{ second_string == 'b' }.all
      ).to eq [instance1]
    end

    it "combines existence nodes" do
      expect(
        klass.where{ !second_string }.and(base_filter).all
      ).to eq [instance4]
    end

    it "allows combinations with .and " do
      expect(
        base_filter.and{ second_string == 'b' }.all
      ).to eq [instance1]
    end
  end

  context "when sending another instance of conditions" do
    let(:second_filter) { klass.where{ second_string == 'b' } }

    it "allows combinations with .where " do
      expect(
        base_filter.where(second_filter).all
      ).to eq [instance1]
    end

    it "allows combinations with .and " do
      expect(
        base_filter.and(second_filter).all
      ).to eq [instance1]
    end
  end

end
