# frozen_string_literal: true

module A2A
  # Defines base properties shared by all security scheme objects.
  class SecuritySchemeBase < ProtocolStruct
    # @return [String, nil] An optional description for the security scheme.
    attribute? :description, Types::String.optional
  end
end
