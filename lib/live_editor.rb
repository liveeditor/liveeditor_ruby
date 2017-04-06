require 'live_editor/client'
require 'live_editor/response'
require 'live_editor/auth'

module LiveEditor
  # Sets client to use for calls to API.
  #
  # Arguments:
  #
  # -  `client` - Client to use for calls to API. Typically, you'll pass a
  #    configured instance of `LiveEditor::API::Client` as this argument.
  def self.client=(client)
    @@client = client
  end

  # Returns client to use for calls to API.
  def self.client
    @@client
  end

  # Returns query string for single or array of string relationship includes.
  def self.include_query_string_for(include)
    if include
      includes = include.is_a?(Array) ? include : [include]
      "include=#{includes.join(',')}"
    else
      ''
    end
  end
end
