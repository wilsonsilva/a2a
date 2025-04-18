# frozen_string_literal: true

module A2A
  # Response to a `tasks/cancel` request. Contains the updated Task object or an error.
  class CancelTaskResponse < JSONRPCResponse
    # @return [Task, nil] The canceled task information if successful.
    attribute? :result, Types::Constructor(Task).optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end
end
