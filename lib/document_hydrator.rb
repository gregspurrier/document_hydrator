require 'document_hydrator/inflector'
if defined? Mongo
  require 'document_hydrator/hydration_proc/mongo'
end

module DocumentHydrator
  class <<self
    # Given a +document+ hash, a path or array of paths describing locations of object IDs within
    # the hash, and a function that will convert object IDs to a hash of subdocument hashes indexed
    # by object ID, modifies the document hash so that all of the IDs referenced by the paths are
    # replaced with the corresponding subdocuments.
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
      ids.each {|id| dehydrated_subdocuments[id].replace(hydrated_subdocuments[id])}

      documents
    end

  private

    def replace_ids_with_dehydrated_documents(document, path_steps, dehydrated_documents)
      step = path_steps.first
      next_steps = path_steps[1..-1]
      if document.has_key?(step)
        subdocument = document[step]
        if next_steps.empty?
          # End of the path, do the hydration, dropping any _id or _ids suffix
          if step =~ /_ids?$/
            document.delete(step)
            step = step.sub(/_id(s?)$/, '')
            step = Inflector.pluralize(step) if $1 == 's'
          end
          document[step] =
            case subdocument
            when Array
              subdocument.map {|id| dehydrated_documents[id] }
            when nil
              nil
            else
              dehydrated_documents[subdocument]
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
