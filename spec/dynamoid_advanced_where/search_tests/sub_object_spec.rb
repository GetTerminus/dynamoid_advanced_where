require 'spec_helper'

RSpec.describe 'Searching sub fields' do
  let(:default_klass) do
    new_class do
      field :raw1, :raw
      field :map1, :map
    end
  end

  let!(:instance) do
    default_klass.create(
      map1: {g: {a: 123, b: 'asdf'}},
      raw1: {g: {y: 123, x: 'asdf'}}
    )
  end

  let!(:instance2) do
    default_klass.create(
      map1: {g: {a: 456, b: 'xxx'}},
      raw1: {g: {y: 789, x: 'zzz'}}
    )
  end

  it 'allows searching a map by a sub field' do
    expect(
      default_klass.where do |r|
        r.map1.sub_field(:g, :a, type: :number) > 150
      end.all
    ).to eq [instance2]
  end
end
