# frozen_string_literal: true

module A2A
  # Represents the status of a task at a specific point in time.
  class TaskStatus < ProtocolStruct
    # @return [String] The current state of the task.
    attribute :state, TaskState

    # @return [Message, nil] An optional message associated with the current status.
    attribute? :message, Types::Constructor(Message).optional

    # @return [DateTime, nil] The timestamp when this status was recorded (ISO 8601 format).
    attribute? :timestamp, Types::JSON::DateTime.optional
  end
end
