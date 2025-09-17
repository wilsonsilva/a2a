# frozen_string_literal: true

module A2A
  # Request to cancel a currently running task.
  class CancelTaskRequest < JSONRPC::Request
    # @return [String] Method name for canceling a task.
    METHOD = 'tasks/cancel'

    # @return [String] Method name for canceling a task.
    attribute :method, Types::String.constant(METHOD)

    # @return [TaskIdParams] Parameters for the cancel task method.
    attribute :params, Types::Constructor(TaskIdParams)

    # @return [String] Method name for canceling a task.
    def method = attributes[:method]
  end
end
