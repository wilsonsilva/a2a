# frozen_string_literal: true

module A2A
  # Defines a security scheme using OpenID Connect.
  class OpenIdConnectSecurityScheme < SecuritySchemeBase
    # @return [String] The type of the security scheme. Must be 'openIdConnect'.
    attribute :type, Types::String.constant('openIdConnect')

    # @return [String] The OpenID Connect Discovery URL for the OIDC provider's metadata.
    attribute :open_id_connect_url, Types::String
  end
end
