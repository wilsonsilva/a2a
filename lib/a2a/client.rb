# lib/a2a/client.rb
# Implements the A2A client for making requests to an A2A server.
# Includes streaming support using 'http' gem and 'event_stream_parser'.
# Fixed initialization to fetch agent card when URL is provided.
# Added resubscribe_task and supports methods.

require 'http' # Using the 'http' gem (formerly http.rb)
require 'json'
require 'securerandom'
require_relative 'types' # Load the type definitions

# --- Add dependency for SSE Parser ---
# Ensure 'event_stream_parser' is added to your gemspec
begin
  require 'event_stream_parser'
rescue LoadError
  raise LoadError, "The 'event_stream_parser' gem is required for streaming support. Please add it to your Gemfile or gemspec."
end


module A2A
  # --- Custom Error Classes ---
  class ClientError < StandardError; end
  class HTTPError < ClientError
    attr_reader :status_code, :response_body
    def initialize(message, status_code = nil, response_body = nil)
      super(message)
      @status_code = status_code
      @response_body = response_body
    end
  end
  class JSONError < ClientError; end
  class RPCError < ClientError
    attr_reader :code, :rpc_message, :data
    def initialize(message, code = nil, rpc_message = nil, data = nil)
      super(message)
      @code = code
      @rpc_message = rpc_message
      @data = data
    end
  end
  class StreamingError < ClientError; end

  # --- A2A Client Implementation ---
  class Client
    attr_reader :url, :agent_card

    # Initializes the client with either an AgentCard struct or a direct URL.
    # If only a URL is provided, it attempts to fetch the AgentCard from the
    # standard well-known path.
    # @param agent_card [A2A::AgentCard, nil] The agent card struct.
    # @param url [String, nil] The direct URL to the A2A agent endpoint or base URL for card discovery.
    # @param options [Hash] Additional options (e.g., :timeout, :headers, :agent_card_path).
    # @raise [ArgumentError] If neither agent_card nor url is provided.
    # @raise [A2A::ClientError] If fetching the agent card fails during initialization.
    def initialize(agent_card: nil, url: nil, options: {})
      agent_card_path = options.fetch(:agent_card_path, '/.well-known/agent.json')

      if agent_card
        # Ensure agent_card is the correct type if provided
        unless agent_card.is_a?(A2A::AgentCard)
          raise ArgumentError, "agent_card must be an instance of A2A::AgentCard"
        end
        @agent_card = agent_card
        # Use the URL from the provided card
        @url = @agent_card.url
        unless @url
          raise ArgumentError, "Provided agent_card must have a url attribute."
        end
      elsif url
        # URL provided, need to fetch the agent card
        begin
          # Assume the provided URL might be the base URL or the direct endpoint URL.
          base_url_for_fetch = url.chomp('/') # Simple base URL assumption
          @agent_card = self.class.fetch_agent_card(base_url_for_fetch, agent_card_path)
          # Set the client's primary URL to the one specified in the fetched card
          @url = @agent_card.url
          unless @url
            raise ClientError, "Fetched agent card from #{base_url_for_fetch} is missing the required url attribute."
          end
        rescue A2A::HTTPError, A2A::JSONError => e
          # Wrap fetch errors in a ClientError for initialization context
          raise ClientError, "Failed to fetch agent card during initialization from #{url}: #{e.message}"
        rescue Dry::Struct::Error => e
          raise ClientError, "Fetched agent card from #{url} has invalid structure: #{e.message}"
        end
        # Validate fetched card object type (fetch_agent_card already returns AgentCard or raises)
        unless @agent_card.is_a?(A2A::AgentCard)
          raise ClientError, "Fetching agent card from #{url} did not return a valid A2A::AgentCard object."
        end
      else
        raise ArgumentError, 'Must provide either agent_card or url'
      end

      # --- Setup common options ---
      default_headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json' # Default accept type
      }
      @options = {
        timeout: options.fetch(:timeout, 30), # Default timeout 30 seconds
        headers: default_headers.merge(options.fetch(:headers, {}))
      }.freeze
      @streaming_headers = @options[:headers].merge('Accept' => 'text/event-stream')
      @streaming_timeout_options = {
        connect: options[:connect_timeout] || @options[:timeout] || 10, # Connect timeout
        read: options[:read_timeout] # Read timeout per chunk (nil = no timeout)
      }.compact
    end

    # Sends a task to the agent (non-streaming).
    # @param params [Hash, A2A::TaskSendParams] Parameters for sending the task.
    # @return [A2A::SendTaskResponse] The response from the agent.
    def send_task(params)
      request_params = params.is_a?(A2A::TaskSendParams) ? params : A2A::TaskSendParams.new(params)
      request = A2A::SendTaskRequest.new(params: request_params)
      response_data = send_request(request)
      A2A::SendTaskResponse.new(response_data)
    end

    # Gets the status and details of a task.
    # @param params [Hash, A2A::TaskQueryParams] Parameters for querying the task.
    # @return [A2A::GetTaskResponse] The response from the agent.
    def get_task(params)
      request_params = params.is_a?(A2A::TaskQueryParams) ? params : A2A::TaskQueryParams.new(params)
      request = A2A::GetTaskRequest.new(params: request_params)
      response_data = send_request(request)
      A2A::GetTaskResponse.new(response_data)
    end

    # Cancels a task.
    # @param params [Hash, A2A::TaskIdParams] Parameters identifying the task.
    # @return [A2A::CancelTaskResponse] The response from the agent.
    def cancel_task(params)
      request_params = params.is_a?(A2A::TaskIdParams) ? params : A2A::TaskIdParams.new(params)
      request = A2A::CancelTaskRequest.new(params: request_params)
      response_data = send_request(request)
      A2A::CancelTaskResponse.new(response_data)
    end

    # Sets the push notification configuration for a task.
    # @param params [Hash, A2A::TaskPushNotificationConfig] The push notification config.
    # @return [A2A::SetTaskPushNotificationResponse] The response from the agent.
    def set_task_push_notification(params)
      request_params = params.is_a?(A2A::TaskPushNotificationConfig) ? params : A2A::TaskPushNotificationConfig.new(params)
      request = A2A::SetTaskPushNotificationRequest.new(params: request_params)
      response_data = send_request(request)
      A2A::SetTaskPushNotificationResponse.new(response_data)
    end

    # Gets the push notification configuration for a task.
    # @param params [Hash, A2A::TaskIdParams] Parameters identifying the task.
    # @return [A2A::GetTaskPushNotificationResponse] The response from the agent.
    def get_task_push_notification(params)
      request_params = params.is_a?(A2A::TaskIdParams) ? params : A2A::TaskIdParams.new(params)
      request = A2A::GetTaskPushNotificationRequest.new(params: request_params)
      response_data = send_request(request)
      A2A::GetTaskPushNotificationResponse.new(response_data)
    end

    # Sends a task and yields streaming responses via SSE.
    # Uses the 'http' gem for the POST request and 'event_stream_parser' for parsing.
    # Note: This method blocks the calling thread until the stream is closed or an error occurs.
    # @param params [Hash, A2A::TaskSendParams] Parameters for sending the task.
    # @yield [A2A::SendTaskStreamingResponse] Each event received from the server.
    # @raise [ArgumentError] If no block is given.
    # @raise [A2A::HTTPError] If the initial HTTP request fails or returns non-success status.
    # @raise [A2A::StreamingError] If an error occurs during streaming or processing.
    # @raise [A2A::JSONError] If an event's data is not valid JSON.
    def send_task_streaming(params, &block)
      unless block_given?
        raise ArgumentError, "A block is required to handle streaming responses"
      end

      request_params = params.is_a?(A2A::TaskSendParams) ? params : A2A::TaskSendParams.new(params)
      request = A2A::SendTaskStreamingRequest.new(params: request_params)

      execute_streaming_request(request, &block)
    end

    # Alias for compatibility with the provided CLI example
    alias_method :send_task_subscribe, :send_task_streaming

    # Resubscribes to updates for a task after a potential connection interruption.
    # Uses the 'http' gem for the POST request and 'event_stream_parser' for parsing.
    # Note: This method blocks the calling thread until the stream is closed or an error occurs.
    # @param params [Hash, A2A::TaskQueryParams] Parameters for resubscribing.
    # @yield [A2A::SendTaskStreamingResponse] Each event received from the server.
    # @raise [ArgumentError] If no block is given.
    # @raise [A2A::HTTPError] If the initial HTTP request fails or returns non-success status.
    # @raise [A2A::StreamingError] If an error occurs during streaming or processing.
    # @raise [A2A::JSONError] If an event's data is not valid JSON.
    def resubscribe_task(params, &block)
      unless block_given?
        raise ArgumentError, "A block is required to handle streaming responses"
      end

      request_params = params.is_a?(A2A::TaskQueryParams) ? params : A2A::TaskQueryParams.new(params)
      request = A2A::TaskResubscriptionRequest.new(params: request_params)

      # The response format for resubscribe is the same as sendSubscribe
      execute_streaming_request(request, &block)
    end

    # Checks if the agent likely supports a given capability based on its AgentCard.
    # This is a client-side check and relies on the card being fetched successfully.
    # @param capability [Symbol, String] The capability to check (e.g., :streaming, :push_notifications).
    # @return [Boolean] True if the capability is declared as true in the agent card, false otherwise.
    def supports(capability)
      # Ensure agent card and capabilities exist
      return false unless @agent_card&.capabilities

      case capability.to_sym
      when :streaming
        @agent_card.capabilities.streaming == true
      when :push_notifications
        @agent_card.capabilities.push_notifications == true
        # Add other capabilities here if needed
        # when :state_transition_history
        #   @agent_card.capabilities.state_transition_history == true
      else
        false # Unknown capability
      end
    end

    # --- Private Helper Methods ---
    private

    # Executes a non-streaming JSON-RPC request.
    # @param request [A2A::JSONRPCRequest] The request object.
    # @return [Hash] The parsed JSON response data (raw hash from JSON parse).
    # @raise [A2A::HTTPError] If there's an HTTP issue.
    # @raise [A2A::JSONError] If the response is not valid JSON.
    # @raise [A2A::RPCError] If the response contains a JSON-RPC error.
    def send_request(request)
      http_client = HTTP.timeout(@options[:timeout]).headers(@options[:headers])
      response = http_client.post(@url, json: request.to_json_hash)

      unless response.status.success?
        raise HTTPError.new("HTTP Error: #{response.status.code} #{response.status.reason}", response.status.code, response.body.to_s)
      end

      begin
        response_body = response.parse(:json)
        response_data = response_body # Return raw hash

        error_info = response_data['error'] || response_data[:error]
        if error_info
          code = error_info['code'] || error_info[:code]
          message = error_info['message'] || error_info[:message] || 'Unknown RPC Error'
          data = error_info['data'] || error_info[:data]
          raise RPCError.new(message, code, message, data)
        end

        response_data
      rescue JSON::ParserError => e
        raise JSONError, "JSON Parse Error: #{e.message}"
      rescue HTTP::Error => e
        raise HTTPError, "HTTP Client Error: #{e.message}"
      end
    end

    # Executes a streaming request (SSE POST) and parses events.
    # @param request [A2A::JSONRPCRequest] The request object (SendTaskStreamingRequest or TaskResubscriptionRequest).
    # @yield [A2A::SendTaskStreamingResponse] Each event received from the server.
    # @raise [A2A::HTTPError] If the initial HTTP request fails.
    # @raise [A2A::StreamingError] If streaming or processing fails.
    # @raise [A2A::JSONError] If event data is invalid JSON.
    def execute_streaming_request(request, &block)
      http_client = HTTP.headers(@streaming_headers)
                      .timeout(@streaming_timeout_options)

      response = nil
      begin
        response = http_client.post(@url, json: request.to_json_hash)

        unless response.status.success?
          raise HTTPError.new("Streaming HTTP Error: #{response.status.code} #{response.status.reason}",
                              response.status.code, response.body.to_s)
        end

        parser = EventStreamParser::Parser.new

        response.body.each do |chunk|
          parser.feed(chunk) do |_type, data, _id, _reconnection_time|
            begin
              next if data.nil? || data.empty?
              parsed_data = JSON.parse(data)
              response_obj = A2A::SendTaskStreamingResponse.new(parsed_data)
              block.call(response_obj)
            rescue JSON::ParserError => e
              puts "WARN: JSON Parse Error in stream: #{e.message} - Data: #{data}"
              # Decide if this should halt processing
            rescue StandardError => e
              puts "ERROR: Error processing stream event: #{e.message}\n#{e.backtrace.join("\n")}"
              raise StreamingError, "Error processing stream event: #{e.message}"
            end
          end
        end

      rescue HTTP::Error => e
        raise HTTPError, "HTTP Client Error during streaming request for #{request.method}: #{e.message}"
      rescue StandardError => e
        response&.connection&.close
        raise StreamingError, "Streaming failed for #{request.method}: #{e.message}" unless e.is_a?(StreamingError) || e.is_a?(HTTPError)
        raise
      end
    end

    # --- Card Resolver (Class Method) ---
    # Fetches the agent card from the well-known path relative to a base URL.
    # @param base_url [String] The base URL of the agent.
    # @param agent_card_path [String] The path to the agent card JSON.
    # @return [A2A::AgentCard] The fetched agent card.
    # @raise [A2A::HTTPError] If the card cannot be fetched or HTTP error occurs.
    # @raise [A2A::JSONError] If the card is not valid JSON or structure mismatch.
    # @raise [Dry::Struct::Error] If the fetched data doesn't match AgentCard structure.
    def self.fetch_agent_card(base_url, agent_card_path = '/.well-known/agent.json')
      card_url = "#{base_url.chomp('/')}/#{agent_card_path.sub(%r{^/}, '')}"
      begin
        response = HTTP.headers('Accept' => 'application/json').get(card_url)
        unless response.status.success?
          raise HTTPError.new("Failed to fetch agent card: #{response.status}", response.status.code, response.body.to_s)
        end
        card_data = response.parse(:json)
        AgentCard.new(card_data)
      rescue JSON::ParserError => e
        raise JSONError, "Failed to parse agent card JSON from #{card_url}: #{e.message}"
      rescue HTTP::Error => e
        raise HTTPError, "HTTP error fetching agent card from #{card_url}: #{e.message}"
      end
    end

  end
end
