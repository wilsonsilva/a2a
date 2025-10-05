# frozen_string_literal: true

module A2A
  # Defines configuration details for the OAuth 2.0 Authorization Code flow.
  class AuthorizationCodeOAuthFlow < ProtocolStruct
    # @return [String] The authorization URL to be used for this flow.
    #   This MUST be a URL and use TLS.
    attribute :authorization_url, Types::String

    # @return [String] The token URL to be used for this flow.
    #   This MUST be a URL and use TLS.
    attribute :token_url, Types::String

    # @return [String, nil] The URL to be used for obtaining refresh tokens.
    #   This MUST be a URL and use TLS.
    attribute? :refresh_url, Types::String.optional

    # @return [Hash] The available scopes for the OAuth2 security scheme. A map between the scope
    #   name and a short description for it.
    attribute :scopes, Types::Hash.map(Types::String, Types::String)
  end
end
