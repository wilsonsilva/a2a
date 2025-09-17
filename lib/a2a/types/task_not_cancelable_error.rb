# frozen_string_literal: true

module A2A
  # Error non-cancelable tasks (-32002)
  #
  # Raised when a task cannot be canceled. An attempt was made to cancel a task that is not in a cancelable state
  # (e.g., it has already reached a terminal state like completed, failed, or canceled).
  #
  # @api public
  #
  # @example Create a task not cancelable error
  #   error = JSONRPC::Errors::TaskNotCancelableError.new
  #
  class TaskNotCancelableError < JSONRPC::Error
    # Creates a new Task Not Cancelable Error with code -32002
    #
    # @api public
    #
    # @example Create a task not cancelable error with default message
    #   error = JSONRPC::TaskNotCancelableError.new
    #
    # @example Create a task not cancelable error with exception details
    #   error = JSONRPC::TaskNotCancelableError.new(data: { exception: 'Task reached terminal state' }, request_id: 1)
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'Task cannot be canceled.',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: ErrorCodes::TASK_NOT_CANCELABLE,
        data:,
        request_id:
      )
    end
  end
end
