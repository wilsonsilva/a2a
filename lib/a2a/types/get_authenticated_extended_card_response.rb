# frozen_string_literal: true

module A2A
  # Response to a `agent/getAuthenticatedExtendedCard` request.
  # Returns an extended AgentCard with additional details for authenticated users.
  class GetAuthenticatedExtendedCardResponse < JSONRPC::Response
    # @return [AgentCard, nil] The authenticated extended agent card if successful.
    attribute? :result, Types::Constructor(AgentCard).optional

    # @return [JSONRPC::Error, nil] Error information if the request failed.
    attribute? :error, Types::Constructor(JSONRPC::Error).optional
  end
end
