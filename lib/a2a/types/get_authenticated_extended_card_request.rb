# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC request for the `agent/getAuthenticatedExtendedCard` method.
  class GetAuthenticatedExtendedCardRequest < JSONRPC::Request
    # @return [String] Method name for getting authenticated extended card.
    METHOD = 'agent/getAuthenticatedExtendedCard'

    # @return [String] Method name for getting authenticated extended card.
    attribute :method, Types::String.constant(METHOD)

    # @return [String] Method name for getting authenticated extended card.
    def method = attributes[:method]
  end
end
