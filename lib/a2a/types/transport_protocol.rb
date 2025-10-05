# frozen_string_literal: true

module A2A
  # Supported A2A transport protocols.
  TransportProtocol = Types::String.enum('JSONRPC', 'GRPC', 'HTTP+JSON')
end
