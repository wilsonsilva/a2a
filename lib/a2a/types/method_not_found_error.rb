# frozen_string_literal: true

module A2A
  # Error for method not found
  class MethodNotFoundError < JSONRPCError
    # @return [Integer] Error code (-32601)
    attribute :code, Types::Integer.constant(ErrorCodes::METHOD_NOT_FOUND)

    # @return [String] Error message
    attribute :message, Types::String.constant('Method not found')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.default(nil)
  end
end
