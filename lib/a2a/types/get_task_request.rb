# frozen_string_literal: true

module A2A
  # Request to retrieve the current state of a task.
  class GetTaskRequest < JSONRPCRequest
    # @return [String] Method name for getting task status.
    attribute :method, Types::String.constant('tasks/get')

    # @return [TaskQueryParams] Parameters for the get task method.
    attribute :params, Types::Constructor(TaskQueryParams)

    # @return [String] Method name for getting task status.
    def method = attributes[:method]
  end
end
