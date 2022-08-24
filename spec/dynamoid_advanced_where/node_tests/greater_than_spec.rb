require 'spec_helper'

RSpec.describe 'Greater Than' do
  let(:klass) do
    new_class(table_name: 'greater_than_test', table_opts: { key: :bar }) do
      field :simple_string
      field :num, :number
      field :num_int, :integer
      field :string_date, :datetime, store_as_string: true
      field :int_datetime, :datetime
      field :int_date, :date
      field :str_date, :date, store_as_string: true
    end
  end

  describe 'of a string field' do
    let!(:item1) { klass.create(simple_string: 'foo') }

    it 'raises an error' do
      expect do
        klass.where { simple_string > 5 }.all
      end.to raise_error(
        NoMethodError
      )
    end
  end

  describe 'of a number field' do
    it 'raises an error if the value is not a numeric' do
      expect do
        klass.where { num > '5' }.all
      end.to raise_error(
        ArgumentError,
        'unable to compare number to `String`'
      )
    end

    it 'only returns items matching the conditions' do
      klass.create(num: 2)
      item1 = klass.create(num: 5)
      expect(klass.where { num > 4 }.all).to eq [item1]
    end
  end

  describe 'of a integer field' do
    it 'raises an error if the value is not a numeric' do
      expect do
        klass.where { num_int > '5' }.all
      end.to raise_error(
        ArgumentError,
        'unable to compare number to `String`'
      )
    end

    it 'only returns items matching the conditions' do
      klass.create(num_int: 2)
      item1 = klass.create(num: 5)
      expect(klass.where { num_int > 4 }.all).to eq [item1]
    end
  end

  describe 'of a string date field' do
    it 'raises an error' do
      expect do
        klass.where { string_date > 1.day.ago }.all
      end.to raise_error(
        ArgumentError,
        /unable to find field type for/
      )
    end
  end

  describe 'of a int datetime field' do
    let!(:created_today) { klass.create(int_datetime: Time.now) }
    let!(:created_yesterday) { klass.create(int_datetime: Time.now - 3600 * 24) }

    it 'raises an error if the value is not a date or time' do
      expect do
        klass.where { int_datetime > 'abc' }.all
      end.to raise_error(
        ArgumentError,
        'unable to compare datetime to type String'
      )
    end

    it 'filters based on a date' do
      expect(
        klass.where { int_datetime > Date.today }.all
      ).to eq [created_today]
    end

    it 'filters based on a time' do
      expect(
        klass.where { int_datetime > Time.now - 60 }.all
      ).to eq [created_today]
    end
  end

  describe 'of a int date field' do
    let!(:created_today) { klass.create(int_date: Date.today) }
    let!(:created_yesterday) { klass.create(int_date: Date.yesterday - 1.day) }

    it 'raises an error if the value is string' do
      expect  do
        klass.where { int_date > 'abc' }.all
      end.to raise_error(
        ArgumentError,
        'unable to compare date to type String'
      )
    end

    it 'raises an error if the value is a datetime' do
      expect do
        klass.where { int_date > DateTime.now }.all
      end.to raise_error(
        ArgumentError,
        'unable to compare date to type DateTime'
      )
    end

    it 'raises an error if the value is a time' do
      expect do
        klass.where { int_date > Time.now }.all
      end.to raise_error(
        ArgumentError,
        'unable to compare date to type Time'
      )
    end

    it 'filters based on a date' do
      expect(
        klass.where { int_date > Date.yesterday }.all
      ).to eq [created_today]
    end
  end
end
