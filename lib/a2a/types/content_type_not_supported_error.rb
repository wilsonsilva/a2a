# frozen_string_literal: true

module A2A
  # Error for unsupported content types (-32005)
  #
  # Raised when a Media Type provided in the request's message.parts (or implied for an artifact)
  # is not supported by the agent or the specific skill being invoked.
  #
  # @api public
  #
  # @example Create a content type not supported error
  #   error = JSONRPC::ContentTypeNotSupportedError.new
  #
  class ContentTypeNotSupportedError < JSONRPC::Error
    # Creates a new Content Type Not Supported Error with code -32005
    #
    # @api public
    #
    # @example Create a content type not supported error with default message
    #   error = JSONRPC::ContentTypeNotSupportedError.new
    #
    # @example Create a content type not supported error with exception details
    #   error = JSONRPC::ContentTypeNotSupportedError.new(data: { content_type: 'application/xml' }, request_id: 1)
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'Incompatible content types.',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: ErrorCodes::CONTENT_TYPE_NOT_SUPPORTED,
        data:,
        request_id:
      )
    end
  end
end
