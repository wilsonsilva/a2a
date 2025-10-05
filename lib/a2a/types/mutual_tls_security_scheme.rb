# frozen_string_literal: true

module A2A
  # Defines a security scheme using mTLS authentication.
  class MutualTLSSecurityScheme < SecuritySchemeBase
    # @return [String] The type of the security scheme. Must be 'mutualTLS'.
    attribute :type, Types::String.constant('mutualTLS')
  end
end
