# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC error object.
  class JSONRPCError < ProtocolStruct
    # @return [Integer] A number indicating the error type that occurred.
    attribute :code, Types::Integer.constant(ErrorCodes::PARSE_ERROR)

    # @return [String] A string providing a short description of the error.
    attribute :message, Types::String.constant('Invalid JSON payload')

    # @return [Object, nil] Optional additional data about the error.
    attribute? :data, Types::Nominal::Any.optional
  end
end
