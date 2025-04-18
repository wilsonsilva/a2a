# frozen_string_literal: true

require 'dry/inflector'
require 'zeitwerk'

# Encapsulates all the gem's logic
module A2A
  # @!visibility private
  # @return [Dry::Inflector] The inflector instance used for camelizing keys
  INFLECTOR = Dry::Inflector.new
end

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'a2a' => 'A2A',
  'json_deserialization' => 'JSONDeserialization',
  'jsonrpc_error' => 'JSONRPCError',
  'jsonrpc_message' => 'JSONRPCMessage',
  'jsonrpc_request' => 'JSONRPCRequest',
  'jsonrpc_response' => 'JSONRPCResponse',
  'json_parse_error' => 'JSONParseError'
)
loader.collapse("#{__dir__}/a2a/types")
loader.enable_reloading
loader.setup
loader.eager_load
