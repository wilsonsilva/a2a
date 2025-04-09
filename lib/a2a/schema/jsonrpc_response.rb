# frozen_string_literal: true

module A2A
  module Schema
    # JSON-RPC response message
    class JSONRPCResponse < JSONRPCMessage
      attr_accessor :result, :error

      # @param id [String, Integer, nil] Response ID matching request
      # @param result [Object, nil] Result on success
      # @param error [JSONRPCError, nil] Error on failure
      def initialize(id:, result: nil, error: nil)
        super(id: id)
        @result = result
        @error = error
      end

      REQUIRED_FIELDS = [:jsonrpc].freeze
    end
  end
end