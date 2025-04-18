# frozen_string_literal: true

module A2A
  # Response to a `tasks/pushNotification/get` request. Contains the TaskPushNotificationConfig or an error.
  class GetTaskPushNotificationResponse < JSONRPCResponse
    # @return [TaskPushNotificationConfig, nil] The push notification config if successful.
    attribute? :result, Types::Constructor(TaskPushNotificationConfig).optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end
end
