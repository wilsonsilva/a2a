# frozen_string_literal: true

module A2A
  # Error for unsupported operations
  class UnsupportedOperationError < JSONRPCError
    # @return [Integer] Error code (-32004)
    attribute :code, Types::Integer.constant(ErrorCodes::UNSUPPORTED_OPERATION)

    # @return [String] Error message
    attribute :message, Types::String.constant('This operation is not supported')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.constant(nil)
  end
end
