require 'spec_helper'

RSpec.describe 'Scan vs Query' do
  let(:default_klass) do
    new_class do
      field :bar
    end
  end

  let(:customized_klass) do
    new_class(table_name: :other_table, table_opts: {key: :fooy})
  end

  it 'performs a scan when the search lacks the ID field' do
    default_klass.create(bar: 'foo')
    default_klass.create(bar: 'baz')
    query_mat = default_klass.where{ bar == 'foo' }.query_materializer
    expect(query_mat).to receive(:each_page_via_scan).once.and_call_original
    expect(query_mat).not_to receive(:each_page_via_query)
    expect(query_mat.each.to_a.length).to eq 1
  end

  it 'performs a query when searching only by ID' do
    persisted = default_klass.create
    default_klass.create
    query_mat = default_klass.where{ id == persisted.id }.query_materializer

    expect(query_mat).to receive(:each_page_via_query).once.and_call_original
    expect(query_mat).not_to receive(:each_page_via_scan)
    expect(query_mat.each.to_a.length).to eq 1
  end

  it 'performs a query when searching by custom ID' do
    persisted = customized_klass.create
    query_mat = customized_klass.where{ fooy == persisted.fooy }.query_materializer
    expect(query_mat).to receive(:each_page_via_query).once.and_call_original
    expect(query_mat).not_to receive(:each_page_via_scan)
    expect(query_mat.each.to_a.length).to eq 1
  end

  it 'performs a scan when searching by negated ID' do
    customized_klass.create(fooy: 'bar')
    customized_klass.create(fooy: 'foo')
    query_mat = customized_klass.where{ !(fooy == 'foo') }.query_materializer
    expect(query_mat).to receive(:each_page_via_scan).once.and_call_original
    expect(query_mat).not_to receive(:each_page_via_query)
    expect(query_mat.each.to_a.length).to eq 1
  end

  it 'performs a scan when searching by ne ID' do
    customized_klass.create(fooy: 'bar')
    customized_klass.create(fooy: 'foo')
    query_mat = customized_klass.where{ fooy != 'foo' }.query_materializer
    expect(query_mat).to receive(:each_page_via_scan).once.and_call_original
    expect(query_mat).not_to receive(:each_page_via_query)
    expect(query_mat.each.to_a.length).to eq 1
  end

  describe "complex queryable" do
    it 'performs a query when searching only by ID' do
      obj = default_klass.create(bar: 'baz')
      query_mat = default_klass.where{ (id == obj.id) & (bar == 'baz') }.query_materializer
      expect(query_mat).to receive(:each_page_via_query).once.and_call_original
      expect(query_mat).not_to receive(:each_page_via_scan)
      expect(query_mat.each.to_a.length).to eq 1
    end
  end

  describe "a range lookup during a query" do
    let(:default_klass) do
      new_class(table_name: 'compound') do
        field :bar, :number
        self.range_key = :bar
      end
    end

    it "appends the range key to the filter" do
      default_klass.create(id: 'a', bar: 1)
      default_klass.create(id: 'a', bar: 2)

      query_mat = default_klass.where{ (id == 'a') & (bar > 1) }.query_materializer

      expect(query_mat.send(:client)).to receive(:query).with(a_hash_including(
        key_condition_expression: a_string_matching(/#[^ ]+ +> +:[^ ]+/)
      )).and_call_original

      expect(query_mat.each.to_a.length).to eq 1
    end
  end
end
