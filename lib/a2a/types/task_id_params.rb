# frozen_string_literal: true

module A2A
  # Basic parameters used for task ID operations.
  class TaskIdParams < ProtocolStruct
    # @return [String] The unique identifier of the task.
    attribute :id, Types::String

    # @return [Hash, nil] Optional metadata to include with the operation.
    attribute? :metadata, Types::Hash.optional
  end
end
