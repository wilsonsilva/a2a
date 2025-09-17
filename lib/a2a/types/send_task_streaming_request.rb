# frozen_string_literal: true

module A2A
  # Request to send a message/initiate a task and subscribe to streaming updates.
  class SendTaskStreamingRequest < JSONRPC::Request
    # @return [String] Method name for sending a task message and subscribing to updates.
    METHOD = 'tasks/sendSubscribe'

    # @return [String] Method name for sending a task message and subscribing to updates.
    attribute :method, Types::String.constant(METHOD)

    # @return [TaskSendParams] Parameters for the streaming task send method.
    attribute :params, Types::Constructor(TaskSendParams)

    # @return [String] Method name for sending a task message and subscribing to updates.
    def method = attributes[:method]
  end
end
