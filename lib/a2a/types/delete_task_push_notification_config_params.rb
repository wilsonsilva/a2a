# frozen_string_literal: true

module A2A
  # Defines parameters for deleting a specific push notification configuration for a task.
  class DeleteTaskPushNotificationConfigParams < TaskIdParams
    # @return [String] The ID of the push notification configuration to delete.
    attribute :push_notification_config_id, Types::String
  end
end
