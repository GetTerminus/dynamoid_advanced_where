require 'spec_helper'

RSpec.describe "Less Than" do
  let(:klass) do
    new_class(table_name: 'less_than_test', table_opts: {key: :bar} ) do
      field :simple_string
      field :string_date, :datetime, store_as_string: true
      field :int_date, :datetime
      field :num, :number
    end
  end

  describe "of a string field" do
    let!(:item1) { klass.create(simple_string: 'foo') }

    it "raises an error" do
      expect{
        klass.where{ simple_string < 5}.all
      }.to raise_error(
        ArgumentError,
        'Unable to perform less than on field of type string'
      )
    end
  end

  describe "of a number field" do
    it "raises an error if the value is not a numeric" do
      expect{
        klass.where{ num < '5'}.all
      }.to raise_error(
        ArgumentError,
        'Unable to perform less than on value of type String'
      )
    end

    it "only returns items matching the conditions" do
      klass.create(num: 7)
      item1 = klass.create(num: 2)
      expect(klass.where{ num < 4}.all).to eq [item1]
    end
  end

  describe "of a string date field" do
    it "raises an error" do
      expect{
        klass.where{ string_date < 1.day.ago}.all
      }.to raise_error(
        ArgumentError,
        'Unable to perform less than on value of type Datetime unless stored as an integer'
      )
    end
  end

  describe "of a float date field" do
    let!(:created_today) { klass.create(int_date: Time.now) }
    let!(:created_yesterday) { klass.create(int_date: Time.now - 3600 * 24) }

    it "raises an error if the value is not a date or time" do
      expect{
        klass.where{ int_date < 'abc'}.all
      }.to raise_error(
        ArgumentError,
        'Unable to perform less than on datetime with a value of type String. Expected Date or Time'
      )
    end

    it "filters based on a date" do
      expect(
        klass.where{ int_date < Date.today}.all
      ).to eq [created_yesterday]
    end

    it "filters based on a time" do
      expect(
        klass.where{ int_date < Time.now - 60}.all
      ).to eq [created_yesterday]
    end
  end
end
