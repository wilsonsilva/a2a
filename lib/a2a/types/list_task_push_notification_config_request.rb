# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC request for the `tasks/pushNotificationConfig/list` method.
  class ListTaskPushNotificationConfigRequest < JSONRPC::Request
    # @return [String] Method name for listing push notification configurations.
    METHOD = 'tasks/pushNotificationConfig/list'

    # @return [String] Method name for listing push notification configurations.
    attribute :method, Types::String.constant(METHOD)

    # @return [ListTaskPushNotificationConfigParams] Parameters for listing push notification configurations.
    attribute :params, Types::Constructor(ListTaskPushNotificationConfigParams)

    # @return [String] Method name for listing push notification configurations.
    def method = attributes[:method]
  end
end
