require 'spec_helper'

RSpec.describe 'Scan vs Query' do
  let(:default_klass) do
    new_class do
      field :bar
      field :other_indexed_field
      field :other_indexed_field2

      self.range_key = :bar
    end
  end

  let(:customized_klass) do
    new_class(table_name: :other_table)
  end

  let!(:record1) { default_klass.create(id: 'a', bar: 'foo') }
  let!(:record3) { default_klass.create(id: 'a', bar: 'fooz') }
  let!(:record2) { default_klass.create(id: 'b', bar: 'fooy') }


  it 'it queries ascending by default' do
    expect(default_klass.advanced_where{|r| r.id == 'a' }.to_a).to eq [record1, record3]
  end

  it 'it queries descending when requested' do
    expect(default_klass.advanced_where{|r| r.id == 'a' }.scan_index_forward(false).to_a).to eq [record1, record3].reverse
  end

  it 'rasies an wrror when trying to scan backwards' do
    expect{ default_klass.advanced_where{|r| r.bar == 'a' }.scan_index_forward(false).to_a }.to raise_error
  end
end
