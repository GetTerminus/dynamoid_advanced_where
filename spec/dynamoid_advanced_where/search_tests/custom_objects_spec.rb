require 'spec_helper'

RSpec.describe 'Searching custom objects' do
  let(:sub_object) do
    Struct.new(:foo) do
      def self.dynamoid_dump(item)
        item.to_h
      end

      def self.dynamoid_load(data)
        new(**data.transform_keys(&:to_sym))
      end
    end
  end

  let(:default_klass) do
    x = sub_object
    new_class do
      field :custom_klass, x
    end
  end

  describe 'searching a simple subfield' do
    let!(:instance) { default_klass.create(custom_klass: sub_object.new(123)) }
    let!(:instance2) { default_klass.create(custom_klass: sub_object.new(456)) }

    it 'allows searching by number sub type' do
      expect(
        default_klass.where do |r|
          r.custom_klass.sub_field(:foo, type: :number) > 150
        end.all
      ).to eq [instance2]
    end
  end

  describe 'it allows searching deeply into a sub object' do
    let!(:instance) { default_klass.create(custom_klass: sub_object.new({a: [1, {c: 5}]})) }
    let!(:instance2) { default_klass.create(custom_klass: sub_object.new({a: [1, {c: 9}]})) }

    it 'allows searching by number sub type deeply nested' do
      expect(
        default_klass.where do |r|
          r.custom_klass.sub_field(:foo, :a, 1, :c, type: :number) > 6
        end.all
      ).to eq [instance2]
    end
  end
end
