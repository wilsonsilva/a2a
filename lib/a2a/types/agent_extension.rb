# frozen_string_literal: true

module A2A
  # A declaration of a protocol extension supported by an Agent.
  class AgentExtension < ProtocolStruct
    # @return [URI] The unique URI identifying the extension.
    attribute :uri, Types::URI

    # @return [String, nil] A human-readable description of how this agent uses the extension.
    attribute? :description, Types::String.optional

    # @return [Boolean] If true, the client must understand and comply with the extension's requirements
    #   to interact with the agent.
    attribute? :required, Types::Bool.default(false)

    # @return [Hash, nil] Optional, extension-specific configuration parameters.
    attribute? :params, Types::Hash.optional
  end
end
