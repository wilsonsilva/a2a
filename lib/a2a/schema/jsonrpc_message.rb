# frozen_string_literal: true

module A2A
  module Schema
    # Base JSON-RPC message
    class JSONRPCMessage < SchemaObject
      attr_accessor :jsonrpc, :id

      # @param id [String, Integer, nil] Optional message ID
      def initialize(id: nil)
        @jsonrpc = '2.0'
        @id = id
      end

      REQUIRED_FIELDS = [:jsonrpc].freeze
    end
  end
end