# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC response object.
  class JSONRPCResponse < JSONRPCMessage
    # @return [Object, nil] The result of the method invocation. Required on success.
    attribute? :result, Types::Nominal::Any.optional

    # @return [JSONRPCError, nil] An error object if an error occurred during the request. Required on failure.
    attribute? :error, Types::Constructor(JSONRPCError).optional
  end
end
