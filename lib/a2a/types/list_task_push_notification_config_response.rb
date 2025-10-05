# frozen_string_literal: true

module A2A
  # Response to a `tasks/pushNotificationConfig/list` request.
  # Returns an array of all push notification configurations for the specified task.
  class ListTaskPushNotificationConfigResponse < JSONRPC::Response
    # @return [Array<TaskPushNotificationConfig>, nil] Array of push notification configurations if successful.
    attribute? :result, Types::Array.of(Types::Constructor(TaskPushNotificationConfig)).optional

    # @return [JSONRPC::Error, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPC::Error).optional
  end
end
