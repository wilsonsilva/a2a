# frozen_string_literal: true

module A2A
  # Request to retrieve the current state of a task.
  class GetTaskRequest < JSONRPC::Request
    # @return [String] Method name for getting task status.
    METHOD = 'tasks/get'

    # @return [String] Method name for getting task status.
    attribute :method, Types::String.constant(METHOD)

    # @return [TaskQueryParams] Parameters for the get task method.
    attribute :params, Types::Constructor(TaskQueryParams)

    # @return [String] Method name for getting task status.
    def method = attributes[:method]
  end
end
