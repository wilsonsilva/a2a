# frozen_string_literal: true

module A2A
  # The AgentCard is a self-describing manifest for an agent. It provides essential
  # metadata including the agent's identity, capabilities, skills, supported
  # communication methods, and security requirements.
  class AgentCard < ProtocolStruct
    # @return [String] The version of the A2A protocol this agent supports.
    attribute :protocol_version, Types::String.default('0.3.0')

    # @return [String] A human-readable name for the agent.
    attribute :name, Types::String

    # @return [String] A human-readable description of the agent, assisting users and other agents
    #   in understanding its purpose.
    attribute :description, Types::String

    # @return [URI] The preferred endpoint URL for interacting with the agent.
    #   This URL MUST support the transport specified by 'preferred_transport'.
    attribute :url, Types::URI

    # @return [String] The transport protocol for the preferred endpoint (the main 'url' field).
    #   If not specified, defaults to 'JSONRPC'.
    attribute? :preferred_transport, Types::String.default('JSONRPC')

    # @return [Array<AgentInterface>, nil] A list of additional supported interfaces (transport and URL combinations).
    #   This allows agents to expose multiple transports, potentially at different URLs.
    attribute? :additional_interfaces, Types::Array.of(Types::Constructor(AgentInterface)).optional

    # @return [URI, nil] An optional URL to an icon for the agent.
    attribute? :icon_url, Types::URI.optional

    # @return [AgentProvider, nil] Information about the provider of the agent.
    attribute? :provider, Types::Constructor(AgentProvider).optional

    # @return [String] The agent's own version number. The format is defined by the provider.
    attribute :version, Types::String

    # @return [URI, nil] An optional URL to the agent's documentation.
    attribute? :documentation_url, Types::URI.optional

    # @return [AgentCapabilities] A declaration of optional capabilities supported by the agent.
    attribute :capabilities, Types::Constructor(AgentCapabilities)

    # @return [Hash<String, SecurityScheme>, nil] A declaration of the security schemes available to authorize requests.
    #   The key is the scheme name. Follows the OpenAPI 3.0 Security Scheme Object.
    attribute? :security_schemes, Types::Hash.map(Types::Symbol | Types::String, Types::Constructor(SecurityScheme)).optional

    # @return [Array<Hash>, nil] A list of security requirement objects that apply to all agent interactions.
    #   Each object lists security schemes that can be used. Follows the OpenAPI 3.0 Security Requirement Object.
    attribute? :security, Types::Array.of(Types::Hash.map(Types::String | Types::Symbol, Types::Array.of(Types::String))).optional

    # @return [Array<String>] Default set of supported input MIME types for all skills, which can be
    #   overridden on a per-skill basis.
    attribute :default_input_modes, Types::Array.of(Types::String)

    # @return [Array<String>] Default set of supported output MIME types for all skills, which can be
    #   overridden on a per-skill basis.
    attribute :default_output_modes, Types::Array.of(Types::String)

    # @return [Array<AgentSkill>] The set of skills, or distinct capabilities, that the agent can perform.
    attribute :skills, Types::Array.of(Types::Constructor(AgentSkill))

    # @return [Boolean] If true, the agent can provide an extended agent card with additional details
    #   to authenticated users. Defaults to false.
    attribute? :supports_authenticated_extended_card, Types::Bool.default(false)

    # @return [Array<AgentCardSignature>, nil] JSON Web Signatures computed for this AgentCard.
    attribute? :signatures, Types::Array.of(Types::Constructor(AgentCardSignature)).optional
  end
end
