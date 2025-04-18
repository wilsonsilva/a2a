# frozen_string_literal: true

module A2A
  # Response to a `tasks/pushNotification/set` request. Contains the TaskPushNotificationConfig or an error.
  class SetTaskPushNotificationResponse < JSONRPCResponse
    # @return [TaskPushNotificationConfig, nil] The push notification config if successful.
    attribute? :result, Types::Constructor(TaskPushNotificationConfig).optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end
end
