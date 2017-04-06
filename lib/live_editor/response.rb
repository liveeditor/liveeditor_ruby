module LiveEditor
  class ParseError; end

  class Response
    # Attributes
    attr_accessor :response, :refreshed_oauth

    # Constructor.
    def initialize(response, refreshed_oauth = nil)
      @response = response
      @refreshed_oauth = refreshed_oauth
    end

    # Returns whether or not the response is an error.
    def error?
      self.response.is_a?(Net::HTTPClientError) || self.response.is_a?(Net::HTTPServerError)
    end

    # Returns an array of errors if available.
    def errors
      # JSON API errors
      if self.error? && self.json_api? && self.parsed_body.has_key?('errors')
        response_errors = self.parsed_body['errors']
        translated_errors = {}

        response_errors.each do |error|
          key = error['source']['pointer'].sub('/data/attributes/', '')

          if translated_errors.has_key?(key)
            translated_errors[key] << error['detail']
          else
            translated_errors[key] = [ error['detail'] ]
          end
        end

        translated_errors
      # Plain old JSON error
      elsif self.error? && self.json? && self.parsed_body.has_key?('error')
        [{ 'detail' => self.parsed_body['error'] }]
      # No errors
      else
        []
      end
    end

    # Returns whether or not the response has JSON-formatted content.
    def json?
      parsed_body_valid?
    end

    # Returns whether or not the response has JSON API-formatted content.
    def json_api?
      !self.response.content_type.nil? &&
        self.response.content_type.start_with?('application/vnd.api+json') &&
        self.json?
    end

    # Parses response body and caches it so the parsing doesn't keep happening
    # and happening on multiple calls to this method. If the response body
    # isn't valid JSON, then this method returns a
    #{ }`LiveEditor::ParserError`.
    def parsed_body
      @parsed_body ||= JSON.parse(self.response.body)
    rescue JSON::ParserError, TypeError
      @parsed_body = LiveEditor::ParseError
    end

    # Returns whether or not OAuth credentials were refreshed during the
    # request.
    def refreshed_oauth?
      !self.refreshed_oauth.nil?
    end

    # Returns whether or not the response was successful.
    def success?
      self.response.is_a?(Net::HTTPSuccess) || self.response.is_a?(Net::HTTPRedirection)
    end

    # Returns whether or not the response is unauthorized.
    def unauthorized?
      self.response.is_a?(Net::HTTPUnauthorized)
    end

  private

    # Returns whether or not the JSON-parsed body contains valid data.
    def parsed_body_valid?
      parsed_body != LiveEditor::ParseError
    end
  end
end
