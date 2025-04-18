# frozen_string_literal: true

module A2A
  # Represents the metadata card for an agent, describing its properties and capabilities.
  class AgentCard < ProtocolStruct
    # @return [String] The name of the agent.
    attribute :name, Types::String

    # @return [String, nil] An optional description of the agent.
    attribute? :description, Types::String.optional

    # @return [String] The base URL endpoint for interacting with the agent.
    attribute :url, Types::String

    # @return [AgentProvider, nil] Information about the provider of the agent.
    attribute? :provider, Types::Constructor(AgentProvider).optional

    # @return [String] The version identifier for the agent or its API.
    attribute :version, Types::String

    # @return [String, nil] An optional URL pointing to the agent's documentation.
    attribute? :documentation_url, Types::String.optional

    # @return [AgentCapabilities] The capabilities supported by the agent.
    attribute :capabilities, Types::Constructor(AgentCapabilities)

    # @return [AgentAuthentication, nil] Authentication details required to interact with the agent.
    attribute? :authentication, Types::Constructor(AgentAuthentication).optional

    # @return [Array<String>] Default input modes supported by the agent (e.g., 'text', 'file', 'json').
    attribute? :default_input_modes, Types::Array.of(Types::String).default(['text'].freeze)

    # @return [Array<String>] Default output modes supported by the agent (e.g., 'text', 'file', 'json').
    attribute? :default_output_modes, Types::Array.of(Types::String).default(['text'].freeze)

    # @return [Array<AgentSkill>] List of specific skills offered by the agent.
    attribute :skills, Types::Array.of(Types::Constructor(AgentSkill))
  end
end
