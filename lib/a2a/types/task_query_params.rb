# frozen_string_literal: true

module A2A
  # Parameters used for querying task-related information by ID.
  class TaskQueryParams < TaskIdParams
    # @return [Integer, nil] Optional history length to retrieve for the task.
    attribute? :history_length, Types::Integer.optional
  end
end
