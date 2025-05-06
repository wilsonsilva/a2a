# frozen_string_literal: true

module A2A
  # Request to retrieve the currently configured push notification configuration for a task.
  class GetTaskPushNotificationRequest < JSONRPCRequest
    # @return [String] Method name for getting task notification configuration.
    METHOD = 'tasks/pushNotification/get'

    # @return [String] Method name for getting task notification configuration.
    attribute :method, Types::String.constant(METHOD)

    # @return [TaskIdParams] Parameters for the get task push notification config method.
    attribute :params, Types::Constructor(TaskIdParams)

    # @return [String] Method name for getting task notification configuration.
    def method = attributes[:method]
  end
end
