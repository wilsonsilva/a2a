# frozen_string_literal: true

module A2A
  # Error for invalid agent responses (-32006)
  #
  # Raised when agent generates an invalid response for the requested method.
  #
  # @api public
  #
  # @example Create an invalid agent response error
  #   error = JSONRPC::InvalidAgentResponseError.new
  #
  class InvalidAgentResponseError < JSONRPC::Error
    # Creates a new Invalid Agent Response Error with code -32006
    #
    # @api public
    #
    # @example Create an invalid agent response error with default message
    #   error = JSONRPC::InvalidAgentResponseError.new
    #
    # @example Create an invalid agent response error with exception details
    #   error = JSONRPC::InvalidAgentResponseError.new(data: { response_type: 'malformed' }, request_id: 1)
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'Invalid agent response type.',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: ErrorCodes::INVALID_AGENT_RESPONSE,
        data:,
        request_id:
      )
    end
  end
end
