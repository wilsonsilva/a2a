# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC request for the `tasks/pushNotificationConfig/set` method.
  class SetTaskPushNotificationConfigRequest < JSONRPC::Request
    # @return [String] Method name for setting task push notification configuration.
    METHOD = 'tasks/pushNotificationConfig/set'

    # @return [String] Method name for setting task push notification configuration.
    attribute :method, Types::String.constant(METHOD)

    # @return [TaskPushNotificationConfig] Parameters for setting the push notification configuration.
    attribute :params, Types::Constructor(TaskPushNotificationConfig)

    # @return [String] Method name for setting task push notification configuration.
    def method = attributes[:method]
  end
end
