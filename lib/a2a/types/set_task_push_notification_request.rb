# frozen_string_literal: true

module A2A
  # Request to set or update the push notification config for a task.
  class SetTaskPushNotificationRequest < JSONRPCRequest
    # @return [String] Method name for setting a task notifications.
    attribute :method, Types::String.constant('tasks/pushNotification/set')

    # @return [TaskPushNotificationConfig] Parameters for the set task push notification method.
    attribute :params, Types::Constructor(TaskPushNotificationConfig)

    # @return [String] Method name for setting a task notifications.
    def method = attributes[:method]
  end
end
