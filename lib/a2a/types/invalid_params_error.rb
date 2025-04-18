# frozen_string_literal: true

module A2A
  # Error for invalid parameters
  class InvalidParamsError < JSONRPCError
    # @return [Integer] Error code (-32602)
    attribute :code, Types::Integer.constant(ErrorCodes::INVALID_PARAMS)

    # @return [String] Error message
    attribute :message, Types::String.constant('Invalid parameters')

    # @return [Object, nil] Additional error data
    attribute? :data, Types::Nominal::Any.optional
  end
end
