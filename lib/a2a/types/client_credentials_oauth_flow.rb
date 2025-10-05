# frozen_string_literal: true

module A2A
  # Defines configuration details for the OAuth 2.0 Client Credentials flow.
  class ClientCredentialsOAuthFlow < ProtocolStruct
    # @return [URI] The token URL to be used for this flow. This MUST be a URL.
    attribute :token_url, Types::URI

    # @return [URI, nil] The URL to be used for obtaining refresh tokens. This MUST be a URL.
    attribute? :refresh_url, Types::URI.optional

    # @return [Hash] The available scopes for the OAuth2 security scheme. A map between the scope
    #   name and a short description for it.
    attribute :scopes, Types::Hash.map(Types::String, Types::String)
  end
end
