# frozen_string_literal: true

module A2A
  # Response to a `message/stream` request.
  # The server may send multiple response objects for a single request.
  # Returns a Message, Task, or streaming update events.
  class SendStreamingMessageResponse < JSONRPC::Response
    # @return [Message, Task, TaskStatusUpdateEvent, TaskArtifactUpdateEvent, nil]
    #   The result, which can be a Message, Task, or streaming update event.
    attribute? :result, Types::Any.optional

    # @return [JSONRPC::Error, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPC::Error).optional
  end
end
