# frozen_string_literal: true

module A2A
  # Defines a security scheme using an API key.
  class APIKeySecurityScheme < SecuritySchemeBase
    # @return [String] The type of the security scheme. Must be 'apiKey'.
    attribute :type, Types::String.constant('apiKey')

    # @return [String] The location of the API key.
    attribute :in, Types::String.enum('query', 'header', 'cookie')

    # @return [String] The name of the header, query, or cookie parameter to be used.
    attribute :name, Types::String
  end
end
