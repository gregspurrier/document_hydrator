# DocumentHydrator

DocumentHydrator takes a document, represented as a Ruby Hash, and
efficiently updates it so that embedded references to other documents
are replaced with their corresponding subdocuments.

Along with the document, DocumentHydrator takes a path (or array of
paths) specifying the location of the references to be expanded and a
Proc--known as the hydration proc--that is capable of providing
expanded subdocuments for those references. The hydration proc is
guaranteed to be called at most once during any given invocation of
DocumentHydrator, ensuring efficient hydration of multiple
subdocuments.

## Hydration Procs
Hydration procs are responsible for transforming an array of document
references into a hash that maps those references to their
corresponding subdocuments. The subdocuments must themselves be
hashes.

DocumentHydrator provides a hydration proc factory that makes it
simple to hydrate a document when pulling the subdocuments from a
MongoDB collection. Use of the factory is described in the "Hydrating
Documents with MongoDB Collections" section found later in the
document.

Most of the following examples illustrate DocumentHydrator
functionality that is independent of the choice of hydration proc. In
order to keep them stand-alone, a simple "identity" hydration proc
will be used:

    identity_hydrator = Proc.new do |ids|
      ids.inject({}) do |hash, id|
        hash[id] = { 'id' => id }
        hash
      end
    end

It simply maps IDs to hashes containing the ID under the key 'id'. For
example:

    identity_hydrator.call([1, 2, 3])
    # => {1=>{"id"=>1}, 2=>{"id"=>2}, 3=>{"id"=>3}}

## A Simple Example
Armed with `identity_hydrator`, the simplest example is:
    
    doc = { 'thing' => 1, 'gizmo' => 3 }
    DocumentHydrator.hydrate_document(doc, 'thing', identity_hydrator)
    # => {"thing"=>{"id"=>1},"gizmo"=>3}

In this case DocumentHydrator is asked to hydrate a single document,
`doc`, by replacing the reference found at `doc['thing']` to its
corresponding subdocument, as provided by `identity_hydrator`.

## Paths
In the example above, the path was the name of a top level key in
the document to be hydrated. DocumentHydrator also supports paths
to arrays, nested paths, and nested paths that contain intermediate
arrays.

For example, consider the document:

    status_update = {
      'user' => 19,
      'text' => 'I am loving MongoDB!',
      'likers' => [37, 42, 99],
      'comments' => [
        { 'user' => 88, 'text' => 'Me too!' },
        { 'user' => 99, 'text' => 'Drinking the Kool-Aid, eh?' },
        { 'user' => 88, 'text' => "Don't be a hater. :)" }
      ]
    }

The following are all valid hydration paths referencing user IDs in
`status_update`:

* `'user'` -- single ID
* `'likers'` -- array of IDs
* `'comments.user'` -- single ID contained within an array of objects

## Multi-path Hydration

DocumentHydrator will accept an array of paths to all be hydrated
concurrently:


    DocumentHydrator.hydrate_document(status_update,
      ['user', 'likers', 'comments.user'],
      identity_hydrator)
    pp status_update
    # {"user"=>{"id"=>19},
    #  "text"=>"I am loving MongoDB!",
    #  "likers"=>[{"id"=>37}, {"id"=>42}, {"id"=>99}],
    #  "comments"=>
    #   [{"user"=>{"id"=>88}, "text"=>"Me too!"},
    #    {"user"=>{"id"=>99}, "text"=>"Drinking the KoolAid, eh?"},
    #    {"user"=>{"id"=>88}, "text"=>"Don't be a hater. :)"}]}

Regardless of the number of paths, the hydration is accomplished with a
single call to the hydration proc.

## Multi-document Hydration
Multiple documents may be hydrated at once using
`DocumentHydrator.hydrate_documents`:

    doc1 = { 'thing' => 1, 'gizmo' => 3 }
    doc2 = { 'thing' => 2, 'gizmo' => 3 }
    DocumentHydrator.hydrate_documents([doc1, doc2], 'thing',
      identity_hydrator)
    # => [{"thing"=>{"id"=>1}, "gizmo"=>3}, {"thing"=>{"id"=>2}, "gizmo"=>3}]

The only difference between `hydrate_document` and `hydrate_documents`
is that the latter takes an array of documents. The other parameters
are the same.

## Hydrating Documents with MongoDB Collections
DocumentHydrator provides a hydration proc factory that makes it
simple to hydrate documents with subdocuments that are fecthed from a
MongoDB collection.

The following examples require a bit of setup:

    require 'mongo'
    db = Mongo::Connection.new.db('document_hydrator_example')
    users_collection = db['users']
    users_collection.remove
    users_collection.insert('_id' => 1, 'name' => 'Fred', 'age' => 33)
    users_collection.insert('_id' => 2, 'name' => 'Wilma', 'age' => 30)
    users_collection.insert('_id' => 3, 'name' => 'Barney', 'age' => 29)
    users_collection.insert('_id' => 4, 'name' => 'Betty', 'age' => 28)

Now create a hydration proc that fetches documents from the users
collection:

    user_hydrator = DocumentHydrator::HydrationProc::Mongo.collection(users_collection)

Note that DocumentHydrator::HydrationProc::Mongo is automatically
loaded by `require 'document_dehydrator'` if the MongoDB Ruby Driver
has already been loaded.

Here is the hydration proc in action:

    doc = { 'user_ids' => [1, 3] }
    Documenthydrator.hydrate_document(doc, 'user_ids', user_hydrator)
    # => {"users"=>[{"_id"=>1, "name"=>"Fred", "age"=>33}, {"_id"=>3, "name"=>"Barney", "age"=>29}]}    

### Limiting Fields in Subdocuments
By default a Mongo collection hydrator will return all of the fields
that are present for the subdocument in the database. This can be
changed, however, by passing an optional `:fields` argument to the
factory. This option takes the same form as it does for
Mongo::Collection#find.

For example:

    user_hydrator = DocumentHydrator::HydrationProc::Mongo.collection(users_collection,
      :fields => { '_id' => 0, 'name' => 1 })
    DocumentHydrator.hydrate_document(doc, 'user_ids', user_hydrator)
    # => {"users"=>[{"name"=>"Fred"}, {"name"=>"Barney"}]}

## Supported Rubies
DocumentHydrator has been tested with:

* Ruby 1.8.7 (p334)
* Ruby 1.9.2 (p180)
* JRuby 1.6.2

## Copyright
Copyright (c) 2011 Greg Spurrier. See LICENSE.txt for
further details.
