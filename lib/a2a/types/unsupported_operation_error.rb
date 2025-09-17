# frozen_string_literal: true

module A2A
  # Error for unsupported operations (-32004)
  #
  # Raised when the requested operation or a specific aspect of it (perhaps implied by parameters)
  # is not supported by this server agent implementation. Broader than just method not found.
  #
  # @api public
  #
  # @example Create an unsupported operation error
  #   error = JSONRPC::UnsupportedOperationError.new
  #
  class UnsupportedOperationError < JSONRPC::Error
    # Creates a new Unsupported Operation Error with code -32004
    #
    # @api public
    #
    # @example Create an unsupported operation error with default message
    #   error = JSONRPC::UnsupportedOperationError.new
    #
    # @example Create an unsupported operation error with exception details
    #   error = JSONRPC::UnsupportedOperationError.new(data: { operation: 'streaming' }, request_id: 1)
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'This operation is not supported.',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: ErrorCodes::UNSUPPORTED_OPERATION,
        data:,
        request_id:
      )
    end
  end
end
