# frozen_string_literal: true

module A2A
  # Response to a `message/send` request.
  # Returns either a direct Message reply or the initial Task object.
  class SendMessageResponse < JSONRPC::Response
    # @return [Message, Task, nil] The result, which can be a direct reply Message or the initial Task object.
    attribute? :result, Types::Any.optional

    # @return [JSONRPC::Error, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPC::Error).optional
  end
end
