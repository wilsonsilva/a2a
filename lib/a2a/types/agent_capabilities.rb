# frozen_string_literal: true

module A2A
  # Describes the capabilities of an agent.
  class AgentCapabilities < ProtocolStruct
    # @return [Boolean] Indicates if the agent supports streaming responses.
    attribute? :streaming, Types::Bool.default(false)

    # @return [Boolean] Indicates if the agent supports push notification mechanisms.
    attribute? :push_notifications, Types::Bool.default(false)

    # @return [Boolean] Indicates if the agent supports providing state transition history.
    attribute? :state_transition_history, Types::Bool.default(false)

    # @return [Array<AgentExtension>, nil] A list of protocol extensions supported by the agent.
    attribute? :extensions, Types::Array.of(Types::Constructor(AgentExtension)).optional
  end
end
