# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC request for the `tasks/pushNotificationConfig/get` method.
  class GetTaskPushNotificationConfigRequest < JSONRPC::Request
    # @return [String] Method name for getting task push notification configuration.
    METHOD = 'tasks/pushNotificationConfig/get'

    # @return [String] Method name for getting task push notification configuration.
    attribute :method, Types::String.constant(METHOD)

    # @return [GetTaskPushNotificationConfigParams, TaskIdParams] Parameters for getting a push notification
    #   configuration. The TaskIdParams type is deprecated for this method. Use GetTaskPushNotificationConfigParams
    #   instead.
    attribute :params,
              Types::Constructor(GetTaskPushNotificationConfigParams) | Types::Constructor(TaskIdParams)

    # @return [String] Method name for getting task push notification configuration.
    def method = attributes[:method]
  end
end
