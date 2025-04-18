# frozen_string_literal: true

module A2A
  # Defines the authentication schemes and credentials for an agent.
  class AgentAuthentication < ProtocolStruct
    # @return [Array<String>] List of supported authentication schemes.
    attribute :schemes, Types::Array.of(Types::String)

    # @return [String, nil] Credentials for authentication. Can be a string (e.g., token) or null if not
    # required initially.
    attribute? :credentials, Types::String.optional
  end
end
