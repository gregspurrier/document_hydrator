require 'spec_helper'

describe DocumentHydrator do
  class Dummy
    class <<self
      attr_reader :invocation_count

      def reset_invocation_count
        @invocation_count = 0
      end

      def ids_to_documents(ids)
        @invocation_count += 1
        ids.map { |id| { 'id' => id } }
      end
    end
  end
  
  before(:each) do
    Dummy.reset_invocation_count
    @hydration_proc = lambda { |ids| Dummy.ids_to_documents(ids) }
  end

  describe '.hydrate_document' do
    context 'with a simple path to an array of ids' do
      it 'replaces the array with an array of hydrated documents' do
        orig = { 'key1' => 37, 'users' => [27, 39] }
        expected = orig.dup.tap { |d| d['users'] = Dummy.ids_to_documents(d['users']) }
        DocumentHydrator.hydrate_document(orig.dup, 'users', @hydration_proc).should == expected
      end

      it 'leaves the array empty if it was empty' do
        orig = { 'key1' => 37, 'users' => [] }
        DocumentHydrator.hydrate_document(orig.dup, 'users', @hydration_proc).should == orig
      end

      it 'makes no modification to the document when the path does not exist' do
        orig = { 'key1' => 37, 'users' => [3, 5] }
        DocumentHydrator.hydrate_document(orig.dup, 'losers', @hydration_proc).should == orig
      end
    end

    context 'with a simple path to an individual id' do
      it 'replaces the id with the corresponding hydrated document' do
        orig = { 'key1' => 37, 'user' => 72}
        expected = orig.dup.tap { |d| d['user'] = Dummy.ids_to_documents([d['user']]).first }
        DocumentHydrator.hydrate_document(orig.dup, 'user', @hydration_proc).should == expected
      end
    end

    context 'with a compound path to an array of ids' do
      it 'replaces the array with an array of hydrated documents' do
        orig = { 'key1' => 37, 'foo' => { 'users' => [27, 39] } }
        expected = orig.dup.tap { |d| d['foo']['users'] = Dummy.ids_to_documents(d['foo']['users']) }
        DocumentHydrator.hydrate_document(orig.dup, 'foo.users', @hydration_proc).should == expected
      end

      it 'makes no modification to the document when the path does not exist' do
        orig = { 'key1' => 37, 'foo' => { 'users' => [27, 39] } }
        DocumentHydrator.hydrate_document(orig.dup, 'bar.users', @hydration_proc).should == orig
      end
    end

    context 'with a compound path that includes an array as an intermediate step' do
      it 'hydrates all of the expanded paths' do
        orig = {
          'key1' => 37,
          'foos' => [ { 'users' => [27, 39] }, { 'users' => [27, 39] } ]
        }
        expected = orig.dup.tap do |d|
          d['foos'].each { |subdoc| DocumentHydrator.hydrate_document(subdoc, 'users', @hydration_proc) }
        end
        DocumentHydrator.hydrate_document(orig.dup, 'foos.users', @hydration_proc).should == expected
      end
    end

    context 'with an array of paths' do
      before(:each) do
        @orig = {
          'key1' => 77,
          'users' => [1, 2, 3, 4],
          'stuff' => {
            'monkeys' => [99, 1]
          },
          'blah' => {
            'nested_stuff' => [
              { 'user' => 99 },
              { 'user' => 101 }
            ]
          }
        }
        @paths = ['users', 'stuff.monkeys', 'blah.nested_stuff.user']
      end

      it 'achieves the same result as hydrating each path individually' do
        expected = @orig.dup.tap do |document|
          @paths.each { |path| DocumentHydrator.hydrate_document(document, path, @hydration_proc) }
        end

        DocumentHydrator.hydrate_document(@orig.dup, @paths, @hydration_proc).should == expected
      end

      it 'invokes the hydration proc only once' do
        DocumentHydrator.hydrate_document(@orig.dup, @paths, @hydration_proc)
        Dummy.invocation_count.should == 1
      end
    end
  end

  describe '.hydrate_documents' do
    before(:each) do
      @documents = [
        {
          'random_key' => 37,
          'creator' => 99,
          'users' => [37, 42]
        },
        {
          'random_key' => 37,
          'users' => [88, 42]
        }
      ]
      @paths = ['creator', 'users']
    end

    it 'gives the same result as hydrating each document individually' do
      individual_results = @documents.map { |doc| DocumentHydrator.hydrate_document(doc.dup, @paths, @hydration_proc) }
      DocumentHydrator.hydrate_documents(@documents, @paths, @hydration_proc).should == individual_results
    end

    it 'invokes the hydration proc only once' do
      DocumentHydrator.hydrate_documents(@documents, @paths, @hydration_proc)
      Dummy.invocation_count.should == 1
    end
  end
end
