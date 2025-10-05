# frozen_string_literal: true

module A2A
  # Response to a `tasks/pushNotificationConfig/get` request. Contains the TaskPushNotificationConfig or an error.
  class GetTaskPushNotificationResponse < JSONRPC::Response
    # @return [TaskPushNotificationConfig, nil] The push notification config if successful.
    attribute? :result, Types::Constructor(TaskPushNotificationConfig).optional

    # @return [JSONRPC::Error, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPC::Error).optional
  end
end
