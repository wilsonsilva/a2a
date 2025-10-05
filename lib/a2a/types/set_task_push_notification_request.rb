# frozen_string_literal: true

module A2A
  # Request to set or update the push notification config for a task.
  class SetTaskPushNotificationRequest < JSONRPC::Request
    # @return [String] Method name for setting a task notifications.
    METHOD = 'tasks/pushNotificationConfig/set'

    # @return [String] Method name for setting a task notifications.
    attribute :method, Types::String.constant(METHOD)

    # @return [TaskPushNotificationConfig] Parameters for the set task push notification method.
    attribute :params, Types::Constructor(TaskPushNotificationConfig)

    # @return [String] Method name for setting a task notifications.
    def method = attributes[:method]
  end
end
