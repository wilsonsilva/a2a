# frozen_string_literal: true

module A2A
  # Defines configuration options for a `message/send` or `message/stream` request.
  class MessageSendConfiguration < ProtocolStruct
    # @return [Array<String>, nil] A list of output MIME types the client is prepared to accept in the response.
    attribute? :accepted_output_modes, Types::Array.of(Types::String).optional

    # @return [Integer, nil] The number of most recent messages from the task's history to retrieve in the response.
    attribute? :history_length, Types::Integer.optional

    # @return [PushNotificationConfig, nil] Configuration for the agent to send push notifications for updates after
    #   the initial response.
    attribute? :push_notification_config, Types::Constructor(PushNotificationConfig).optional

    # @return [Boolean] If true, the client will wait for the task to complete. The server may reject this if
    #   the task is long-running.
    attribute? :blocking, Types::Bool.default(false)
  end
end
