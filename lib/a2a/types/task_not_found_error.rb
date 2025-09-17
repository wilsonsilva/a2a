# frozen_string_literal: true

module A2A
  # Error for missing tasks (-32001)
  #
  # Raised when the specified task ID does not correspond to an existing or active task.
  # It might be invalid, expired, or already completed and purged.
  #
  # @api public
  #
  # @example Create a task not found error
  #   error = JSONRPC::TaskNotFoundError.new
  #
  class TaskNotFoundError < JSONRPC::Error
    # Creates a new Task Not Found Error with code -32001
    #
    # @api public
    #
    # @example Create a task not found error with default message
    #   error = JSONRPC::TaskNotFoundError.new
    #
    # @example Create a task not found error with exception details
    #   error = JSONRPC::TaskNotFoundError.new(data: { task_id: 'invalid-id' }, request_id: 1)
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'Task not found.',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: ErrorCodes::TASK_NOT_FOUND,
        data:,
        request_id:
      )
    end
  end
end
