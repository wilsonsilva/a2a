# frozen_string_literal: true

module A2A
  # Error for unsupported push notifications (-32003)
  #
  # Raised when client attempts to use push notification features but the server agent
  # does not support them (i.e., AgentCard.capabilities.pushNotifications is false).
  #
  # @api public
  #
  # @example Create a push notification not supported error
  #   error = JSONRPC::PushNotificationNotSupportedError.new
  #
  class PushNotificationNotSupportedError < JSONRPC::Error
    # Creates a new Push Notification Not Supported Error with code -32003
    #
    # @api public
    #
    # @example Create a push notification not supported error with default message
    #   error = JSONRPC::PushNotificationNotSupportedError.new
    #
    # @example Create a push notification not supported error with exception details
    #   error = JSONRPC::PushNotificationNotSupportedError.new(data: { capability: false }, request_id: 1)
    #
    # @param message [String] short description of the error
    # @param data [Hash, Array, String, Number, Boolean, nil] additional error information
    # @param request_id [String, Integer, nil] the request identifier
    #
    def initialize(
      message = 'Push Notification is not supported.',
      data: nil,
      request_id: nil
    )
      super(
        message,
        code: ErrorCodes::PUSH_NOTIFICATION_NOT_SUPPORTED,
        data:,
        request_id:
      )
    end
  end
end
