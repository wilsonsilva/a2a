# frozen_string_literal: true

module A2A
  module Errors
    # Standard JSON-RPC error codes
    PARSE_ERROR = -32700
    INVALID_REQUEST = -32600
    METHOD_NOT_FOUND = -32601
    INVALID_PARAMS = -32602
    INTERNAL_ERROR = -32603

    # A2A specific error codes
    TASK_NOT_FOUND = -32001
    TASK_NOT_CANCELABLE = -32002
    PUSH_NOTIFICATION_NOT_SUPPORTED = -32003
    UNSUPPORTED_OPERATION = -32004
    INCOMPATIBLE_CONTENT_TYPES = -32005

    # Custom error class for A2A protocol
    class A2AError < StandardError
      attr_reader :code, :data, :task_id

      # @param code [Integer] Error code
      # @param message [String] Error message
      # @param data [Object, nil] Optional error data
      # @param task_id [String, nil] Optional task ID context
      def initialize(code, message, data = nil, task_id = nil)
        super(message)
        @code = code
        @data = data
        @task_id = task_id
      end

      # Convert to a JSON-RPC error object
      # @return [Schema::JSONRPCError] JSON-RPC error representation
      def to_json_rpc_error
        Schema::JSONRPCError.new(
          code: @code,
          message: message,
          data: @data
        )
      end

      # Factory methods for common errors

      # Create a parse error
      # @param message [String] Error message
      # @param data [Object, nil] Optional error data
      # @return [A2AError] Parse error instance
      def self.parse_error(message, data = nil)
        new(PARSE_ERROR, message, data)
      end

      # Create an invalid request error
      # @param message [String] Error message
      # @param data [Object, nil] Optional error data
      # @return [A2AError] Invalid request error instance
      def self.invalid_request(message, data = nil)
        new(INVALID_REQUEST, message, data)
      end

      # Create a method not found error
      # @param method [String] The method that wasn't found
      # @return [A2AError] Method not found error instance
      def self.method_not_found(method)
        new(METHOD_NOT_FOUND, "Method not found: #{method}")
      end

      # Create an invalid params error
      # @param message [String] Error message
      # @param data [Object, nil] Optional error data
      # @return [A2AError] Invalid params error instance
      def self.invalid_params(message, data = nil)
        new(INVALID_PARAMS, message, data)
      end

      # Create an internal error
      # @param message [String] Error message
      # @param data [Object, nil] Optional error data
      # @return [A2AError] Internal error instance
      def self.internal_error(message, data = nil)
        new(INTERNAL_ERROR, message, data)
      end

      # Create a task not found error
      # @param task_id [String] The task ID that wasn't found
      # @return [A2AError] Task not found error instance
      def self.task_not_found(task_id)
        new(TASK_NOT_FOUND, "Task not found: #{task_id}", nil, task_id)
      end

      # Create a task not cancelable error
      # @param task_id [String] The task ID that can't be canceled
      # @return [A2AError] Task not cancelable error instance
      def self.task_not_cancelable(task_id)
        new(TASK_NOT_CANCELABLE, "Task not cancelable: #{task_id}", nil, task_id)
      end

      # Create a push notification not supported error
      # @return [A2AError] Push notification not supported error instance
      def self.push_notification_not_supported
        new(PUSH_NOTIFICATION_NOT_SUPPORTED, "Push notifications are not supported")
      end

      # Create an unsupported operation error
      # @param operation [String] The unsupported operation
      # @return [A2AError] Unsupported operation error instance
      def self.unsupported_operation(operation)
        new(UNSUPPORTED_OPERATION, "Unsupported operation: #{operation}")
      end

      # Create an incompatible content types error
      # @param message [String] Error message
      # @return [A2AError] Incompatible content types error instance
      def self.incompatible_content_types(message)
        new(INCOMPATIBLE_CONTENT_TYPES, message)
      end
    end
  end
end
