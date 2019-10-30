require 'spec_helper'

RSpec.describe 'Contains' do
  let(:klass) do
    new_class(table_name: 'greater_than_test', table_opts: {key: :bar} ) do
      field :simple_string
      field :simple_int, :integer
      field :string_set, :set, of: :string
      field :int_set, :set, of: :integer
    end
  end

  let!(:instance_one) { klass.create(simple_string: 'foobardude', string_set: ['a', 'b'], int_set: [1, 2, 3]) }
  let!(:instance_two) { klass.create(simple_string: 'asfd', string_set: ['t', 'r'], int_set: [5, 6, 7]) }

  it 'raises an error if called on a string' do
    expect {
      klass.where{ simple_int.includes?('a') }.all
    }.to raise_error(
      ArgumentError,
      'Unable to perform includes on field'
    )
  end

  it 'can find based on substring' do
    expect(klass.where{ simple_string.includes?('oo') }.all).to eq [instance_one]
  end

  it 'can find against arrays of strings' do
    expect(klass.where{ string_set.includes?('a') }.all).to eq [instance_one]
  end

  it 'can find against arrays of integers' do
    expect(klass.where{ int_set.includes?(6) }.all).to eq [instance_two]
  end
end
