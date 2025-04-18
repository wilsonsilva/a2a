# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC request object.
  class JSONRPCRequest < JSONRPCMessage
    # @return [String] The name of the method to be invoked.
    attribute :method, Types::String

    # @return [Hash, nil] Parameters for the method. Can be a structured object, an array, or null/omitted.
    attribute? :params, Types::Hash.optional

    # @return [String] The name of the method to be invoked.
    def method = attributes[:method]
  end
end
