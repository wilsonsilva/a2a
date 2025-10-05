# frozen_string_literal: true

module A2A
  # Defines the configuration for the supported OAuth 2.0 flows.
  class OAuthFlows < ProtocolStruct
    # @return [AuthorizationCodeOAuthFlow, nil] Configuration for the OAuth Authorization Code flow.
    #   Previously called accessCode in OpenAPI 2.0.
    attribute? :authorization_code, Types::Constructor(AuthorizationCodeOAuthFlow).optional

    # @return [ClientCredentialsOAuthFlow, nil] Configuration for the OAuth Client Credentials flow.
    #   Previously called application in OpenAPI 2.0.
    attribute? :client_credentials, Types::Constructor(ClientCredentialsOAuthFlow).optional

    # @return [ImplicitOAuthFlow, nil] Configuration for the OAuth Implicit flow.
    attribute? :implicit, Types::Constructor(ImplicitOAuthFlow).optional

    # @return [PasswordOAuthFlow, nil] Configuration for the OAuth Resource Owner Password flow.
    attribute? :password, Types::Constructor(PasswordOAuthFlow).optional
  end
end
