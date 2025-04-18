# frozen_string_literal: true

module A2A
  # Represents a base message for JSON-RPC communication.
  class JSONRPCMessage < ProtocolStruct
    # @return [String] Specifies the JSON-RPC version. Must be "2.0".
    attribute? :jsonrpc, Types::String.constant('2.0')

    # @return [Integer, String, nil] Request identifier. Responses must have the same ID as the request they relate to.
    attribute? :id, (Types::Integer | Types::String).optional
  end
end
