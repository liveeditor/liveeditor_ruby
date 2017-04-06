require 'uri'
require 'live_editor/version'

module LiveEditor
  class OAuthRefreshError < Exception; end

  class Client
    # Default user agent to use for API calls.
    USER_AGENT = "liveeditor_api gem/#{LiveEditor::VERSION} (#{RUBY_PLATFORM}) ruby/#{RUBY_VERSION}"

    # Attributes
    attr_accessor :domain, :port, :_use_ssl, :email, :access_token, :refresh_token
    attr_writer :user_agent # Reader is defined below.
    alias_method :_use_ssl?, :_use_ssl

    # Constructor.
    #
    # Options:
    #
    # -  `domain` - Admin domain to connect to. For example,
    #    `example.liveeditorapp.com`.
    # -  `port` - Port to connect to if different than `80` or `443`.
    # -  `email` - Email used to log in.
    # -  `access_token` - Access token to use for request authorization.
    # -  `refresh_token` - Refresh token to use if `access_token` is not set
    #    or is expired.
    # -  `user_agent` - Overrides default user agent used in request headers.
    # -  `_use_ssl` - Whether or not to connect with SSL.
    def initialize(options = {})
      @domain = options[:domain]
      @port = options[:port]
      @email = options[:email]
      @access_token = options[:access_token]
      @refresh_token = options[:refresh_token]
      @user_agent = options[:user_agent]
      @_use_ssl = options[:_use_ssl]
    end

    # Performs a `GET` operation on the Live Editor API.
    #
    # Arguments:
    #
    # -  `url` - URL path to request. Example: `/site`.
    # -  `service` - Service to send request to. Valid options are `auth`,
    #    `cms`, or `cdn`.
    #
    # Options:
    #
    # -  `authorize` - Whether or not the API request needs to be authorized
    #    with an access token. Defaults to `true`.
    # -  `json_api` - Boolean that indicates whether or not this request must
    #    follow the JSON API specification. Defaults to `true`.
    def get(url, service, options = {})
      uri = self.uri_for(url, service)
      run_request_for(uri, Net::HTTP::Get.new(uri), options)
    end

    # Performs a `PATCH` operation on the Live Editor API.
    #
    # Arguments:
    #
    # -  `url` - URL path to patch to. Example: `/themes/layouts`.
    # -  `service` - Service to send request to. Valid options are `auth`,
    #    `cms`, or `cdn`.
    #
    # Options:
    #
    # -  `payload` - Body data to pass along with request. If you pass a
    #    hash or array for this, it will be serialized into JSON markup.
    # -  `authorize` - Whether or not the API request needs to be authorized
    #    with an access token. Defaults to `true`.
    # -  `json_api` - Boolean that indicates whether or not this request must
    #    follow the JSON API specification. Defaults to `true`.
    # -  `form_data` - Hash for use in normal form `POST` variables. Note
    #    that if you're trying to pass data via a JSON API paylaod (which
    #    applies 90% of the time), you'll instead want to pass that via
    #    the `payload` option.
    def patch(url, service, options = {})
      uri = self.uri_for(url, service)
      run_request_for(uri, Net::HTTP::Patch.new(uri), options)
    end

    # Performs a `POST` operation on the Live Editor API.
    #
    # Arguments:
    #
    # -  `url` - URL path to post to. Example: `/themes/layouts`.
    # -  `service` - Service to send request to. Valid options are `auth`,
    #    `cms`, or `cdn`.
    #
    # Options:
    #
    # -  `payload` - Body data to pass along with request. If you pass a
    #    hash or array for this, it will be serialized into JSON markup.
    # -  `authorize` - Whether or not the API request needs to be authorized
    #    with an access token. Defaults to `true`.
    # -  `json_api` - Boolean that indicates whether or not this request must
    #    follow the JSON API specification. Defaults to `true`.
    # -  `form_data` - Hash for use in normal form `POST` variables. Note
    #    that if you're trying to pass data via a JSON API paylaod (which
    #    applies 90% of the time), you'll instead want to pass that via
    #    the `payload` option.
    def post(url, service, options = {})
      uri = self.uri_for(url, service)
      run_request_for(uri, Net::HTTP::Post.new(uri), options)
    end

    # Performs a `DELETE` operation on the Live Editor API.
    #
    # Arguments:
    #
    # -  `url` - URL path to delete to. Example: `/themes/layouts`.
    # -  `service` - Service to send request to. Valid options are `auth`,
    #    `cms`, or `cdn`.
    #
    # Options:
    #
    # -  `authorize` - Whether or not the API request needs to be authorized
    #    with an access token. Defaults to `true`.
    # -  `json_api` - Boolean that indicates whether or not this request must
    #    follow the JSON API specification. Defaults to `true`.
    def delete(url, service, options = {})
      uri = self.uri_for(url, service)
      run_request_for(uri, Net::HTTP::Post.new(uri), options)
    end

    # Returns `URI` object configured with `domain`, `_use_ssl?`, and provided
    # parameters.
    def uri_for(path, service)
      protocol = self._use_ssl? ? 'https' : 'http'
      api_domain = self.domain.split('.')
      api_domain = api_domain.insert(1, 'api')

      if service == 'auth'
        api_domain[0] = 'auth'
      else
        api_domain = api_domain.insert(1, service)
      end

      api_domain = api_domain.join('.')

      URI "#{protocol}://#{api_domain}#{path}"
    end

    # Returns configuration for user agent.
    def user_agent
      @user_agent ||= USER_AGENT
    end

  private

    # Requests an access token from the API's OAuth endpoint.
    #
    # Raises `LiveEditor::OAuthRefreshError` if it fails refreshing the
    # token.
    def request_access_token!
      oauth = LiveEditor::Auth.new
      response = oauth.request_access_token(self.refresh_token)

      if response.success?
        data = response.parsed_body
        self.access_token = data['access_token']
        self.refresh_token = data['refresh_token']
        data
      else
        raise LiveEditor::OAuthRefreshError
      end
    end

    # Runs request for given URI object and HTTP request object.
    def run_request_for(uri, request, options)
      # Option defaults.
      options[:authorize] = options.has_key?(:authorize) ? options[:authorize] : true
      options[:json_api] = options.has_key?(:json_api) ? options[:json_api] : true

      # Request access token if we're authorizing the request and none is set.
      refreshed_oauth =
        if options[:authorize] && !self.access_token
          request_access_token!
        elsif options[:refreshed_oauth]
          options[:refreshed_oauth]
        end

      # Build request.
      request['User-Agent'] = self.user_agent
      request['Authorization'] = "Bearer #{self.access_token}" if options[:authorize]
      request['Content-Type'] = 'application/vnd.api+json' if options[:json_api] && options[:payload]
      request['Accept'] = 'application/vnd.api+json' if options[:json_api]
      request.set_form_data(options[:form_data]) if options[:form_data]
      request.body = options[:payload].to_json if options[:payload]

      # Do request and return response.
      http_response = Net::HTTP.start(uri.hostname, self.port) { |http| http.request(request) }
      response = LiveEditor::Response.new(http_response, refreshed_oauth)

      # If response was unauthorized, refresh access token and try one more
      # time.
      if response.unauthorized? && options[:authorize] && !refreshed_oauth
        token_refresh_data = request_access_token!
        request['Authorization'] = "Bearer #{self.access_token}"
        run_request_for(uri, request, refreshed_oauth: token_refresh_data)
      # Otherwise, return response as-is.
      else
        response
      end
    end
  end
end
