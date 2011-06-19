require 'mongo'

module DocumentHydrator
  module HydratorProc
    module Mongo
      class <<self
        # Create a hydration proc that fetches subdocuments by ID from
        # the provided collection.
        #
        # coll - The Mongo::Collection containing the subdocuments
        # options - (Optional) hash of options to pass to MongoDB::Collection#find.
        #   Defaults to {}.
        #
        # Returns a Proc that maps IDs to their corresponding subdocuments
        # within the collection.
        def collection(coll, options = {})
          Proc.new do |ids|
            if options[:fields]
              # We need to _id key in order to assemble the results hash.
              # If the caller has requested that it be omitted from the
              # result, re-enable it and then strip later.
              field_selectors = options[:fields]
              id_key = field_selectors.keys.detect { |k| k.to_s == '_id' }
              if id_key && field_selectors[id_key] == 0
                field_selectors.delete(id_key)
                strip_id = true
              end
            end
            subdocuments = coll.find({ '_id' => { '$in' => ids } }, options)
            subdocuments.inject({}) do |hash, subdocument|
              hash[subdocument['_id']] = subdocument
              subdocument.delete('_id') if strip_id
              hash
            end
          end
        end
      end
    end
  end
end
