# frozen_string_literal: true

module A2A
  # Defines a security scheme using HTTP authentication.
  class HTTPAuthSecurityScheme < SecuritySchemeBase
    # @return [String] The type of the security scheme. Must be 'http'.
    attribute :type, Types::String.constant('http')

    # @return [String] The name of the HTTP Authentication scheme to be used in the Authorization header,
    #   as defined in RFC7235 (e.g., "Bearer").
    #   This value should be registered in the IANA Authentication Scheme registry.
    attribute :scheme, Types::String

    # @return [String, nil] A hint to the client to identify how the bearer token is formatted (e.g., "JWT").
    #   This is primarily for documentation purposes.
    attribute? :bearer_format, Types::String.optional
  end
end
