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

    def submitted?
      status.state == 'submitted'
    end

    def working?
      status.state == 'working'
    end

    def input_required?
      status.state == 'input-required'
    end

    def completed?
      status.state == 'completed'
    end

    def canceled?
      status.state == 'canceled'
    end

    def failed?
      status.state == 'failed'
    end

    def unknown?
      status.state == 'unknown'
    end

    def cancelable?
      submitted? || working?
    end

    def cancel(reason)
      message = Message.new(parts: [TextPart.new(text: reason)], role: 'agent')
      copy(status: status.copy(state: 'canceled', message:))
    end

    def add_artifact(artifact)
      copy(artifacts: artifacts.to_a.dup.push(artifact))
    end
  end
end
