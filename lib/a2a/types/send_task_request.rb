# frozen_string_literal: true

module A2A
  # Request to send a message/initiate a task.
  class SendTaskRequest < JSONRPC::Request
    # @return [String] Method name for sending a task message.
    METHOD = 'tasks/send'

    # @return [String] Method name for sending a task message.
    attribute :method, Types::String.constant(METHOD)

    # @return [TaskSendParams] Parameters for the send task method.
    attribute :params, Types::Constructor(TaskSendParams)

    # @return [String] The name of the method to be invoked.
    def method = attributes[:method]
  end
end
