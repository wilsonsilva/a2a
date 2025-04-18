# frozen_string_literal: true

module A2A
  # Represents the push notification information associated with a specific task ID.
  class TaskPushNotificationConfig < ProtocolStruct
    # @return [String] The ID of the task the notification config is associated with.
    attribute :id, Types::String

    # @return [PushNotificationConfig] The push notification configuration details.
    attribute :push_notification_config, Types::Constructor(PushNotificationConfig)
  end
end
