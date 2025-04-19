# frozen_string_literal: true

module A2A
  # Error for task not found
  class TaskNotFoundError < JSONRPCError
    # @return [Integer] Error code (-32001)
    attribute :code, Types::Integer.constant(ErrorCodes::TASK_NOT_FOUND)

    # @return [String] Error message
    attribute :message, Types::String.constant('Task not found')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.constant(nil)
  end
end
