# frozen_string_literal: true

module A2A
  # Error for missing authenticated extended card configuration (-32007)
  #
  # Raised when the agent does not have an Authenticated Extended Card configured.
  #
  # @api public
  #
  # @example Create an authenticated extended card not configured error
  #   error = JSONRPC::AuthenticatedExtendedCardNotConfiguredError.new
  #
  class AuthenticatedExtendedCardNotConfiguredError < JSONRPC::Error
    # Creates a new Authenticated Extended Card Not Configured Error with code -32007
    #
    # @api public
    #
    # @example Create an authenticated extended card not configured error with default message
    #   error = JSONRPC::AuthenticatedExtendedCardNotConfiguredError.new
    #
    # @example Create an authenticated extended card not configured error with exception details
    #   error = JSONRPC::AuthenticatedExtendedCardNotConfiguredError.new(
    #     data: { feature: 'extended_card' }, request_id: 1
    #   )
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'Authenticated Extended Card not configured.',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: ErrorCodes::AUTHENTICATED_EXTENDED_CARD_NOT_CONFIGURED,
        data:,
        request_id:
      )
    end
  end
end
