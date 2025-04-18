# frozen_string_literal: true

module A2A
  # Represents a status update event for a task, typically used in streaming scenarios.
  class TaskStatusUpdateEvent < ProtocolStruct
    # @return [String] The ID of the task being updated.
    attribute :id, Types::String

    # @return [TaskStatus] The new status of the task.
    attribute :status, Types::Constructor(TaskStatus)

    # @return [Boolean] Flag indicating if this is the final update for the task.
    attribute? :final, Types::Bool.default(false)

    # @return [Hash, nil] Optional metadata associated with this update event.
    attribute? :metadata, Types::Hash.optional
  end
end
