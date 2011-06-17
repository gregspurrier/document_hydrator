# DocumentHydrator

DocumentHydrator takes a document, represented as a Ruby Hash, and
efficiently updates it so that embedded references to other documents
are replaced with their corresponding subdocuments.

Along with the document, DocumentHydrator requires a path (or array of
paths) specifying the location of the references to be expanded and a
Proc--known as the hydration proc--that is capable of providing
expanded subdocuments forthose references. The hydration proc is
guaranteed to be called at most once during any invocation of
DocumentHydrator, ensuring efficient hydration of multiple
subdocuments.

## Hydration Procs
DocumentHydrator requires a proc that turns an array of document
references into a hash that maps those references to their
corresponding subdocuments.

Typically the hydration proc will fetch the corresponding documents
from a database. In order to keep this documentation self contained,
however, the examples below use an identity hydration proc that maps
IDs to a hash of documents whose only key is 'id'.

    identity_hydrator = Proc.new do |ids|
      ids.inject({}) do |hash, id|
        hash[id] = { 'id' => id }
        hash
      end
    end

For example:

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
        { 'user' => 99, 'text' => 'Drinking the KoolAid, eh?' },
        { 'user' => 88, 'text' => "Don't be a hater. :)" }
      ]
    }

The following are all valid hydration paths referencing user IDs in `status_update`:

* `'user'` -- single ID
* `'likers'` -- array of IDs
* `'comments.user'` -- single ID contained within an array of objects

## Multi-path Hydration
DocumentHydrator will accept an array of paths to all be hydrated concurrently:

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

## Contributing
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add specs for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright
Copyright (c) 2011 Greg Spurrier. See LICENSE.txt for
further details.
