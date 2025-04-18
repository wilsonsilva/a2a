# frozen_string_literal: true

module A2A
  # Error for invalid JSON payload
  class JSONParseError < JSONRPCError
    # @return [Integer] Error code (-32700)
    attribute :code, Types::Integer.constant(ErrorCodes::PARSE_ERROR)

    # @return [String] Error message
    attribute :message, Types::String.constant('Invalid JSON payload')

    # @return [Object, nil] Additional error data
    attribute? :data, Types::Nominal::Any.optional
  end
end
