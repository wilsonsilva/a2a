# frozen_string_literal: true

module A2A
  # Request to resubscribe to updates for a task after a connection interruption.
  class TaskResubscriptionRequest < JSONRPCRequest
    # @return [String] Method name for resubscribing to task updates.
    METHOD = 'tasks/resubscribe'

    # @return [String] Method name for resubscribing to task updates.
    attribute :method, Types::String.constant(METHOD)

    # @return [TaskQueryParams] Parameters for the task resubscription method.
    attribute :params, Types::Constructor(TaskQueryParams)

    # @return [String] Method name for resubscribing to task updates.
    def method = attributes[:method]
  end
end
