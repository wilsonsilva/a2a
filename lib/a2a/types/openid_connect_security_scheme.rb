# frozen_string_literal: true

module A2A
  # Defines a security scheme using OpenID Connect.
  class OpenIdConnectSecurityScheme < SecuritySchemeBase
    # @return [String] The type of the security scheme. Must be 'openIdConnect'.
    attribute :type, Types::String.constant('openIdConnect')

    # @return [URI] The OpenID Connect Discovery URL for the OIDC provider's metadata.
    attribute :open_id_connect_url, Types::URI
  end
end
