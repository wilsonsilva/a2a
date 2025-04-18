# frozen_string_literal: true

module A2A
  # Error for invalid request structure
  class InvalidRequestError < JSONRPCError
    # @return [Integer] Error code (-32600)
    attribute :code, Types::Integer.constant(ErrorCodes::INVALID_REQUEST)

    # @return [String] Error message
    attribute :message, Types::String.constant('Request payload validation error')

    # @return [Object, nil] Additional error data
    attribute? :data, Types::Nominal::Any.optional
  end
end
