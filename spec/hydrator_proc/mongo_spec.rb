require 'spec_helper'
require 'document_hydrator/hydrator_proc/mongo'

describe DocumentHydrator::HydratorProc::Mongo, '.collection' do
  before(:each) do
    db = Mongo::Connection.new.db('document_hydrator_test')
    @users_collection = db['users']
    @users_collection.remove
    @users_collection.insert('_id' => 1, 'name' => 'Fred')
    @users_collection.insert('_id' => 2, 'name' => 'Wilma')
    @users_collection.insert('_id' => 3, 'name' => 'Barney')
    @users_collection.insert('_id' => 4, 'name' => 'Betty')
  end

  it 'returns a hydration proc that fetches subdocuments from the provided Mongo::Collection' do
    hydrator = DocumentHydrator::HydratorProc::Mongo.collection(@users_collection)
    expected = {
      1 => @users_collection.find_one('_id' => 1),
      3 => @users_collection.find_one('_id' => 3),
    }
    hydrator.call([1,3]).should == expected
  end

  it 'integrates with DocumentHydrator' do
    document = { 'users' => [2, 4] }
    expected = { 'users' => [
        { '_id' => 2, 'name' => 'Wilma' },
        { '_id' => 4, 'name' => 'Betty' }
      ]
    }

    hydrator = DocumentHydrator::HydratorProc::Mongo.collection(@users_collection)
    DocumentHydrator.hydrate_document(document, ['users'], hydrator).should == expected
  end
end
