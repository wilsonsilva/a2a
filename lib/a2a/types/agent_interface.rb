# frozen_string_literal: true

module A2A
  # Declares a combination of a target URL and a transport protocol for interacting with the agent.
  # This allows agents to expose the same functionality over multiple transport mechanisms.
  class AgentInterface < ProtocolStruct
    # @return [URI] The URL where this interface is available. Must be a valid absolute HTTPS URL in production.
    attribute :url, Types::URI

    # @return [String] The transport protocol supported at this URL.
    attribute :transport, Types::String
  end
end
