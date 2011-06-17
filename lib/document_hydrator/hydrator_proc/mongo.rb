require 'mongo'

module DocumentHydrator
  module HydratorProc
    module Mongo
      class <<self
        # Create a hydration proc that fetches subdocuments by ID from
        # the provided collection.
        #
        # coll - The Mongo::Collection containing the subdocuments
        #
        # Returns a Proc that maps IDs to their corresponding subdocuments
        # within the collection.
        def collection(coll)
          Proc.new do |ids|
            subdocuments = coll.find('_id' => { '$in' => ids })
            subdocuments.inject({}) do |hash, subdocument|
              hash[subdocument['_id']] = subdocument
              hash
            end
          end
        end
      end
    end
  end
end
