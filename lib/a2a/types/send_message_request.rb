# frozen_string_literal: true

module A2A
  # Represents a JSON-RPC request for the `message/send` method.
  class SendMessageRequest < JSONRPC::Request
    # @return [String] Method name for sending a message.
    METHOD = 'message/send'

    # @return [String] Method name for sending a message.
    attribute :method, Types::String.constant(METHOD)

    # @return [MessageSendParams] Parameters for sending a message.
    attribute :params, Types::Constructor(MessageSendParams)

    # @return [String] Method name for sending a message.
    def method = attributes[:method]
  end
end
