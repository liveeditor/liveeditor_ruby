module LiveEditor
  module CMS
    class Revision
      # Returns a theme record by ID.
      #
      # Options:
      #
      # -  `include` - Relationship(s) to include with the request. Pass an
      #    array to include multiple.
      def self.find(id, options = {})
        query_string = LiveEditor::include_query_string_for(options[:include])
        query_string = '?' + query_string if !query_string.nil?
        LiveEditor::client.get("/revisions/#{id}#{query_string}", :cms, options)
      end
    end
  end
end
