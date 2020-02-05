require 'spec_helper'

RSpec.describe "Less Than" do
  let(:klass) do
    new_class(table_name: 'less_than_test', table_opts: {key: :bar} ) do
      field :simple_string
      field :num, :number
      field :string_datetime, :datetime, store_as_string: true
      field :int_datetime, :datetime
      field :int_date, :date
      field :str_date, :date, store_as_string: true
    end
  end

  describe "of a string field" do
    let!(:item1) { klass.create(simple_string: 'foo') }

    it "raises an error" do
      expect{
        klass.where{ simple_string < 5}.all
      }.to raise_error(NoMethodError)
    end
  end

  describe "of a number field" do
    it "raises an error if the value is not a numeric" do
      expect{
        klass.where{ num < '5'}.all
      }.to raise_error(
        ArgumentError,
        'unable to compare number to `String`'
      )
    end

    it "only returns items matching the conditions" do
      klass.create(num: 7)
      item1 = klass.create(num: 2)
      expect(klass.where{ num < 4}.all).to eq [item1]
    end
  end

  describe "of a string datetime field" do
    it "raises an error" do
      expect{
        klass.where{ string_datetime < 1.day.ago}.all
      }.to raise_error(
        ArgumentError,
        /unable to find field type for/
      )
    end
  end

  describe "of a int datetime field" do
    let!(:created_today) { klass.create(int_datetime: Time.now) }
    let!(:created_yesterday) { klass.create(int_datetime: Time.now - 3600 * 24) }

    it "raises an error if the value is not a date or time" do
      expect{
        klass.where{ int_datetime < 'abc'}.all
      }.to raise_error(
        ArgumentError,
        'unable to compare datetime to type String'
      )
    end

    it "filters based on a date" do
      expect(
        klass.where{ int_datetime < Date.today}.all
      ).to eq [created_yesterday]
    end

    it "filters based on a time" do
      expect(
        klass.where{ int_datetime < Time.now - 60}.all
      ).to eq [created_yesterday]
    end
  end

  describe "of a string date field" do
    it "raises an error" do
      expect{
        klass.where{ str_date < 1.day.ago.to_date}.all
      }.to raise_error(
        ArgumentError,
        /unable to find field type for/
      )
    end
  end

  describe "of a int date field" do
    let!(:created_today) { klass.create(int_date: Time.now) }
    let!(:created_yesterday) { klass.create(int_date: Time.now - 3600 * 24) }

    it "raises an error if the value is string" do
      expect{
        klass.where{ int_date < 'abc'}.all
      }.to raise_error(
        ArgumentError,
        /unable to compare date to type String/
      )
    end

    it "raises an error if the value is a datetime" do
      expect{
        klass.where{ int_date < DateTime.now}.all
      }.to raise_error(
        ArgumentError,
        /unable to compare date to type DateTime/
      )
    end

    it "raises an error if the value is a time" do
      expect{
        klass.where{ int_date < Time.now}.all
      }.to raise_error(
        ArgumentError,
        'unable to compare date to type Time'
      )
    end

    it "filters based on a date" do
      expect(
        klass.where{ int_date < Date.today}.all
      ).to eq [created_yesterday]
    end
  end
end
