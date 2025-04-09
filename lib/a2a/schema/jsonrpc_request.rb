# frozen_string_literal: true

module A2A
  module Schema
    # JSON-RPC request message
    class JSONRPCRequest < JSONRPCMessage
      attr_accessor :method, :params

      # @param method [String] The RPC method name
      # @param params [Object] The method parameters
      # @param id [String, Integer, nil] Optional message ID
      def initialize(method:, params:, id: nil)
        super(id: id)
        @method = method
        @params = params
      end

      REQUIRED_FIELDS = [:jsonrpc, :method].freeze
    end
  end
end