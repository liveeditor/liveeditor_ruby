module LiveEditor
  class Auth
    SERVICE = :auth

    # Log in to the Live Editor API with email and password. Returns hash
    # containing OAuth data: `access_token`, `refresh_token`, etc.).
    #
    # Arguments:
    #
    # -  `email` - Email to login with.
    # -  `password` - Password to login with.
    def login(email, password)
      LiveEditor::client.post('/oauth/token.json', SERVICE, authorize: false, json_api: false, form_data: {
        grant_type: :password,
        username: email,
        password: password
      })
    end

    # Requests an access token for a given refresh token.
    #
    # Arguments:
    #
    # -  `refresh_token` - Refresh token.
    #
    # Options:
    #
    # -  'port' - Override the port configured for the client for this request.
    def request_access_token(refresh_token, options = {})
      LiveEditor::client.post('/oauth/token.json', SERVICE, authorize: false, json_api: false, port: options[:port], form_data: {
        grant_type: :refresh_token,
        refresh_token: refresh_token
      })
    end
  end
end
