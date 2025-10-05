# frozen_string_literal: true

module A2A
  # Defines a security scheme using OAuth 2.0.
  class OAuth2SecurityScheme < SecuritySchemeBase
    # @return [String] The type of the security scheme. Must be 'oauth2'.
    attribute :type, Types::String.constant('oauth2')

    # @return [OAuthFlows] An object containing configuration information for the supported OAuth 2.0 flows.
    attribute :flows, Types::Constructor(OAuthFlows)

    # @return [URI, nil] URL to the oauth2 authorization server metadata
    #   RFC8414. TLS is required.
    attribute? :oauth2_metadata_url, Types::URI.optional
  end
end
