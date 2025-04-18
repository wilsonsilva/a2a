# frozen_string_literal: true

module A2A
  # Error for internal server errors
  class InternalError < JSONRPCError
    # @return [Integer] Error code (-32603)
    attribute :code, Types::Integer.constant(ErrorCodes::INTERNAL_ERROR)

    # @return [String] Error message
    attribute :message, Types::String.constant('Internal error')

    # @return [Object, nil] Additional error data
    attribute? :data, Types::Nominal::Any.optional
  end
end
