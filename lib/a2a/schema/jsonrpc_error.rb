# frozen_string_literal: true

module A2A
  module Schema
    # JSON-RPC error object
    class JSONRPCError < SchemaObject
      attr_accessor :code, :message, :data

      # @param code [Integer] Error code
      # @param message [String] Error message
      # @param data [Object, nil] Optional error data
      def initialize(code:, message:, data: nil)
        @code = code
        @message = message
        @data = data
      end

      REQUIRED_FIELDS = [:code, :message].freeze
    end
  end
end