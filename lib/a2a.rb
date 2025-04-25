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
  'dsl' => 'DSL',
  'json_deserialization' => 'JSONDeserialization',
  'jsonrpc_error' => 'JSONRPCError',
  'jsonrpc_message' => 'JSONRPCMessage',
  'jsonrpc_request' => 'JSONRPCRequest',
  'jsonrpc_response' => 'JSONRPCResponse',
  'json_parse_error' => 'JSONParseError',
  'sse' => 'SSE'
)
loader.collapse("#{__dir__}/a2a/types")
loader.enable_reloading
loader.setup
loader.eager_load

require 'rack'
require 'json'
require 'securerandom'
require 'uri'
require 'net/http'
require 'base64'

# Convenient access to key components
module A2A
  # Create a new server instance
  # @param agent [Agent] The agent instance
  # @return [Transport] A Rack-compatible server instance
  def self.server(agent, options = {})
    # Create a task manager
    storage = config.create_task_storage
    task_manager = TaskManager.new(storage)

    # Create a task processor
    processor = TaskProcessor.new(agent, task_manager)

    # Create a transport
    Transport.new(agent, task_manager, processor)
  end

  # Run the server
  # @param agent [Agent] The agent instance
  # @param options [Hash] Server options
  # @option options [Integer] :port (3000) The port to listen on
  # @option options [String] :host ('localhost') The host to bind to
  # @option options [Boolean] :streaming (true) Whether to enable streaming
  # @return [void]
  def self.run(agent, options = {})
    require 'rackup/handler/webrick'

    port = options[:port] || 3000
    host = options[:host] || 'localhost'

    app = server(agent, options)

    puts "Starting A2A server on http://#{host}:#{port}"
    puts "Agent: #{agent.card.name}"

    Rackup::Handler::WEBrick.run(app, Host: host, Port: port)
  end
end
