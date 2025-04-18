# frozen_string_literal: true

module A2A
  # Response to a `tasks/get` request. Contains the Task object or an error.
  class GetTaskResponse < JSONRPCResponse
    # @return [Task, nil] The task information if successful.
    attribute? :result, Types::Constructor(Task).optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end
end
