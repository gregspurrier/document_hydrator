module DocumentHydrator
  class <<self
    # Given a +document+ hash, a path or array of paths describing locations of object IDs within
    # the hash, and a function that will convert object IDs to subdocument hashes, modifies the
    # document hash so that all of the IDs referenced by the paths are replaced with the corresponding
    # subdocuments.
    #
    # Path examples:
    #
    #   document = {
    #     'owner' => 99,
    #     'clients' => [100, 101],
    #     'comments' => [
    #       { 'user' => 10, text => 'hi' },
    #       { 'user' => 11, text => 'hello' }
    #     ]
    #   }
    #
    # Each of these are valid paths:
    #   - 'owner'
    #   - 'clients'
    #   - 'comments.user'
    #
    # Returns the document to allow for chaining.
    def hydrate_document(document, path_or_paths, hydration_proc)
      hydrate_documents([document],path_or_paths, hydration_proc)
      document
    end

    def hydrate_documents(documents, path_or_paths, hydration_proc)
      # Traverse the documents replacing each ID with a corresponding dehydrated document
      dehydrated_subdocuments = Hash.new { |h, k| h[k] = Hash.new }
      documents.each do |document|
        paths = path_or_paths.kind_of?(Array) ? path_or_paths : [path_or_paths]
        paths.each do |path|
          replace_ids_with_dehydrated_documents(document, path.split('.'), dehydrated_subdocuments)
        end
      end

      # Rehydrate the documents that we discovered during traversal all in one go
      ids = dehydrated_subdocuments.keys
      hydrated_subdocuments = hydration_proc.call(ids)
      ids.zip(hydrated_subdocuments).each do |id, hydrated_subdocument|
        dehydrated_subdocuments[id].replace(hydrated_subdocument)
      end

      documents
    end

  private

    def replace_ids_with_dehydrated_documents(document, path_steps, dehydrated_documents)
      step = path_steps.first
      next_steps = path_steps[1..-1]
      if document.has_key?(step)
        subdocument = document[step]
        if next_steps.empty?
          # End of the path, do the hydration
          if subdocument.kind_of?(Array)
            document[step] = subdocument.map {|id| dehydrated_documents[id] }
          else
            document[step] = dehydrated_documents[subdocument]
          end
        else
          # Keep on stepping
          if subdocument.kind_of?(Array)
            subdocument.each { |item| replace_ids_with_dehydrated_documents(item, next_steps, dehydrated_documents) }
          else
            replace_ids_with_dehydrated_documents(subdocument, next_steps, dehydrated_documents)
          end
        end
      end
    end
  end
end
