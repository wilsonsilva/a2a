# frozen_string_literal: true

module A2A
  # Represents the provider or organization behind an agent.
  class AgentProvider < ProtocolStruct
    # @return [String] The name of the organization providing the agent.
    attribute :organization, Types::String

    # @return [String] A URL for the agent provider's website or relevant documentation.
    attribute :url, Types::String
  end
end
