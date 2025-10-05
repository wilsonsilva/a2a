# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC request for the `tasks/pushNotificationConfig/delete` method.
  class DeleteTaskPushNotificationConfigRequest < JSONRPC::Request
    # @return [String] Method name for deleting push notification configurations.
    METHOD = 'tasks/pushNotificationConfig/delete'

    # @return [String] Method name for deleting push notification configurations.
    attribute :method, Types::String.constant(METHOD)

    # @return [DeleteTaskPushNotificationConfigParams] Parameters for deleting push notification configurations.
    attribute :params, Types::Constructor(DeleteTaskPushNotificationConfigParams)

    # @return [String] Method name for deleting push notification configurations.
    def method = attributes[:method]
  end
end
