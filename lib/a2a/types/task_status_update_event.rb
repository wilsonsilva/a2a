# frozen_string_literal: true

module A2A
  # An event sent by the agent to notify the client of a change in a task's status.
  # This is typically used in streaming or subscription models.
  class TaskStatusUpdateEvent < ProtocolStruct
    # @return [String] The ID of the task that was updated.
    attribute :task_id, Types::String

    # @return [String] The context ID associated with the task.
    attribute :context_id, Types::String

    # @return [String] The type of this event, used as a discriminator. Always 'status-update'.
    attribute :kind, Types::String.constant('status-update')

    # @return [TaskStatus] The new status of the task.
    attribute :status, Types::Constructor(TaskStatus)

    # @return [Boolean] If true, this is the final event in the stream for this interaction.
    attribute :final, Types::Bool

    # @return [Hash, nil] Optional metadata for extensions.
    attribute? :metadata, Types::Hash.optional
  end
end
