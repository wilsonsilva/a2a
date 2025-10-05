# frozen_string_literal: true

module A2A
  # A discriminated union representing a security scheme that can be used to secure an agent's endpoints.
  # This is a discriminated union type based on the OpenAPI 3.0 Security Scheme Object.
  SecurityScheme = APIKeySecurityScheme |
                   HTTPAuthSecurityScheme |
                   OAuth2SecurityScheme |
                   OpenIdConnectSecurityScheme |
                   MutualTLSSecurityScheme
end
