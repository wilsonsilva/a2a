# frozen_string_literal: true

module A2A
  # AgentCardSignature represents a JWS signature of an AgentCard.
  # This follows the JSON format of an RFC 7515 JSON Web Signature (JWS).
  class AgentCardSignature < ProtocolStruct
    # @return [String] The protected JWS header for the signature. This is a Base64url-encoded
    #   JSON object, as per RFC 7515.
    attribute :protected, Types::String

    # @return [String] The computed signature, Base64url-encoded.
    attribute :signature, Types::String

    # @return [Hash, nil] The unprotected JWS header values.
    attribute? :header, Types::Hash.optional
  end
end
