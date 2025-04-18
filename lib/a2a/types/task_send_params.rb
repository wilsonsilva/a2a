# frozen_string_literal: true

module A2A
  # Parameters for the `tasks/send` method.
  class TaskSendParams < ProtocolStruct
    # @return [String] Unique identifier for the task being initiated or continued.
    attribute :id, Types::String

    # @return [String, nil] Optional identifier for the session this task belongs to. If not provided, a new
    # session might be implicitly created depending on the agent.
    attribute? :session_id, Types::String.optional

    # @return [Message] The message content to send to the agent for processing.
    attribute :message, Types::Constructor(Message)

    # @return [PushNotificationConfig, nil] Optional pushNotification information for receiving notifications about
    # this task. Requires agent capability.
    attribute? :push_notification, Types::Constructor(PushNotificationConfig).optional

    # @return [Integer, nil] Optional parameter to specify how much message history to include in the response.
    attribute? :history_length, Types::Integer.optional

    # @return [Hash, nil] Optional metadata associated with sending this message.
    attribute? :metadata, Types::Hash.optional
  end
end
