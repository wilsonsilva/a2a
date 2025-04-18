# frozen_string_literal: true

module A2A
  # Represents a task being processed by an agent.
  class Task < ProtocolStruct
    # @return [String] Unique identifier for the task.
    attribute :id, Types::String

    # @return [String, nil] Optional identifier for the session this task belongs to.
    attribute? :session_id, Types::String.optional

    # @return [TaskStatus] The current status of the task.
    attribute :status, Types::Constructor(TaskStatus)

    # @return [Array<Artifact>, nil] Optional list of artifacts associated with the task
    # (e.g., outputs, intermediate files).
    attribute? :artifacts, Types::Array.of(Types::Constructor(Artifact)).optional

    # @return [Array<Message>, nil] Optional history of messages exchanged during the task.
    attribute? :history, Types::Array.of(Types::Constructor(Message)).optional

    # @return [Hash, nil] Optional metadata associated with the task.
    attribute? :metadata, Types::Hash.optional
  end
end
