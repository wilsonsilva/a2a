# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC request for the `message/stream` method.
  class SendStreamingMessageRequest < JSONRPC::Request
    # @return [String] Method name for streaming a message.
    METHOD = 'message/stream'

    # @return [String] Method name for streaming a message.
    attribute :method, Types::String.constant(METHOD)

    # @return [MessageSendParams] Parameters for streaming a message.
    attribute :params, Types::Constructor(MessageSendParams)

    # @return [String] Method name for streaming a message.
    def method = attributes[:method]
  end
end
