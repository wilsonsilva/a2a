# frozen_string_literal: true

module A2A
  # Response to a streaming task operation, either through `tasks/sendSubscribe` or a subscription.
  # Contains a TaskStatusUpdateEvent, TaskArtifactUpdateEvent, or an error.
  class SendTaskStreamingResponse < JSONRPCResponse
    # @return [TaskStatusUpdateEvent, TaskArtifactUpdateEvent, nil] Event data if successful.
    attribute? :result do
      Types.Constructor(TaskStatusUpdateEvent) | Types.Constructor(TaskArtifactUpdateEvent)
    end.optional

    # @return [JSONRPCError, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end
end
