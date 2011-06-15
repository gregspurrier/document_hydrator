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

Typically the hydration proc will fetch the corresponding documents
from a database. In order to keep this documentation self contained,
however, the examples below use an identity hydration proc that maps
references to documents containing simply the key 'id' with its value
being the original reference.

    identity_hydrator = Proc.new { |ids| ids.map { |id| { 'id' => id } } }

Armed with `identity_hydrator`, the simplest example is:
    
    doc = { 'thing' => 1, 'gizmo' => 3 }
    DocumentHydrator.hydrate_document(doc, 'thing', identity_hydrator)
    # => {"thing"=>{"id"=>1},"gizmo"=>3}

In this case DocumentHydrator is asked to hydrate a single document,
`doc`, by replacing the reference found at `doc['thing']` to its
corresponding subdocument, as provided by `identity_hydrator`.

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
