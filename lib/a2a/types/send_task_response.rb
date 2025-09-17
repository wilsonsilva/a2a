# frozen_string_literal: true

module A2A
  # Response to a `tasks/send` request.
  # Contains the Task object or an error.
  class SendTaskResponse < JSONRPC::Response
    # @return [Task, nil] The resulting task if successful.
    attribute? :result, Types::Constructor(Task).optional

    # @return [JSONRPC::Error, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPC::Error).optional
  end
end
