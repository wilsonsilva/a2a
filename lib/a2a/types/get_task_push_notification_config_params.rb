# frozen_string_literal: true

module A2A
  # Defines parameters for fetching a specific push notification configuration for a task.
  class GetTaskPushNotificationConfigParams < TaskIdParams
    # @return [String, nil] The ID of the push notification configuration to retrieve.
    attribute? :push_notification_config_id, Types::String.optional
  end
end
