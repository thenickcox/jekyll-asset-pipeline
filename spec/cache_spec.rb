require './spec/helper'

describe Cache do
  describe "class methods" do
    subject { Cache }

    describe "::add(key, value)" do
      before { subject.add('foo', 'bar') }
      specify { subject.instance_variable_get(:@cache)['foo'].must_equal('bar') }
    end

    describe "::has_key?(key)" do
      before { subject.instance_variable_set(:@cache, { 'foo' => 'bar' }) }
      specify { subject.has_key?('foo').must_equal(true) }
      specify { subject.has_key?('bar').must_equal(false) }
    end

    describe "::get(key)" do
      before { subject.instance_variable_set(:@cache, { 'foo' => 'bar' }) }
      specify { subject.get('foo').must_equal('bar') }
    end

    describe "::clear" do
      it "clears cache" do
        Cache.add('foo', 'bar')
        Cache.has_key?('foo').must_equal(true)
        Cache.clear
        Cache.has_key?('foo').must_equal(false)
      end
    end
  end
end
