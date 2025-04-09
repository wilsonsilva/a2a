# frozen_string_literal: true

module A2A
  module Schema
    # Task send parameters
    class TaskSendParams < SchemaObject
      attr_accessor :id, :session_id, :message, :push_notification, :history_length, :metadata

      # @param id [String] Task ID
      # @param message [Message] The message to send
      # @param session_id [String, nil] Optional session ID
      # @param push_notification [PushNotificationConfig, nil] Optional push config
      # @param history_length [Integer, nil] Optional history length to include
      # @param metadata [Hash, nil] Optional metadata
      def initialize(id:, message:, session_id: nil, push_notification: nil,
                     history_length: nil, metadata: nil)
        @id = id
        @session_id = session_id
        @message = message
        @push_notification = push_notification
        @history_length = history_length
        @metadata = metadata
      end

      REQUIRED_FIELDS = [:id, :message].freeze
    end
  end
end