# frozen_string_literal: true

module A2A
  # Represents an artifact update event for a task, typically used in streaming scenarios.
  class TaskArtifactUpdateEvent < ProtocolStruct
    # @return [String] The ID of the task being updated.
    attribute :id, Types::String

    # @return [Artifact] The new or updated artifact for the task.
    attribute :artifact, Types::Constructor(Artifact)

    # @return [Boolean, nil] Flag indicating if this is the final update for the task.
    attribute? :final, Types::Bool.optional

    # @return [Hash, nil] Optional metadata associated with this update event.
    attribute? :metadata, Types::Hash.optional
  end
end
