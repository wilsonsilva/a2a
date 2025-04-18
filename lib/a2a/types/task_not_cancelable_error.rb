# frozen_string_literal: true

module A2A
  # Error for task not cancelable
  class TaskNotCancelableError < JSONRPCError
    # @return [Integer] Error code (-32002)
    attribute :code, Types::Integer.constant(ErrorCodes::TASK_NOT_CANCELABLE)

    # @return [String] Error message
    attribute :message, Types::String.constant('Task cannot be canceled')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.default(nil)
  end
end
