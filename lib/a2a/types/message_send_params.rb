# frozen_string_literal: true

module A2A
  # Defines the parameters for a request to send a message to an agent. This can be used
  # to create a new task, continue an existing one, or restart a task.
  class MessageSendParams < ProtocolStruct
    # @return [Message] The message object being sent to the agent.
    attribute :message, Types::Constructor(Message)

    # @return [MessageSendConfiguration, nil] Optional configuration for the send request.
    attribute? :configuration, Types::Constructor(MessageSendConfiguration).optional

    # @return [Hash, nil] Optional metadata for extensions.
    attribute? :metadata, Types::Hash.optional
  end
end
