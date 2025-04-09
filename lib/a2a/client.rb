require 'http' # Using the 'http' gem (formerly http.rb)
require 'json'
require 'securerandom'
require 'event_stream_parser'

require_relative 'types' # Load the type definitions

module A2A
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
  # ConfigurationError might not be needed with this approach
  # class ConfigurationError < ClientError; end

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
          # For fetching, we need the base URL. We'll derive it simply for now.
          # A more robust approach might involve better base URL detection or requiring it separately.
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
      # Default headers, allowing overrides
      default_headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json' # Default accept type
      }
      # Standard options for non-streaming requests
      @options = {
        timeout: options.fetch(:timeout, 30), # Default timeout 30 seconds
        headers: default_headers.merge(options.fetch(:headers, {}))
      }.freeze

      # Specific headers for streaming requests
      @streaming_headers = @options[:headers].merge('Accept' => 'text/event-stream')
      # Timeouts for http gem streaming (passed directly to post)
      @streaming_timeout_options = {
        connect: options[:connect_timeout] || @options[:timeout] || 10, # Connect timeout
        read: options[:read_timeout] # Read timeout per chunk (nil = no timeout)
        # write: options[:write_timeout] # Write timeout
      }.compact

    end # initialize

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
    # Requires the 'event_stream_parser' gem.
    # Note: This method blocks the calling thread until the stream is closed or an error occurs.
    #       Run in a separate thread if non-blocking behavior is required.
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

      # Prepare the request object
      request_params = params.is_a?(A2A::TaskSendParams) ? params : A2A::TaskSendParams.new(params)
      request = A2A::SendTaskStreamingRequest.new(params: request_params)

      # Prepare the HTTP client and request
      http_client = HTTP.headers(@streaming_headers)
                      .timeout(@streaming_timeout_options) # Apply timeouts

      response = nil
      begin
        # Make the POST request using the URL from the (potentially fetched) agent card
        response = http_client.post(@url, json: request.to_json_hash)

        # Check initial response status
        unless response.status.success?
          raise HTTPError.new("Streaming HTTP Error: #{response.status.code} #{response.status.reason}",
                              response.status.code, response.body.to_s)
        end

        # Initialize the SSE parser
        parser = EventStreamParser::Parser.new

        # Process the streaming response body
        response.body.each do |chunk|
          # Feed chunks to the parser. The block is called for each complete event.
          parser.feed(chunk) do |_type, data, _id, _reconnection_time|
            # _type, _id, _reconnection_time are available from the parser if needed
            begin
              # Skip empty data payloads sometimes sent as keep-alives
              next if data.nil? || data.empty?

              # Parse the JSON data payload of the event
              parsed_data = JSON.parse(data)

              # Instantiate the response object. BaseStruct.new handles key transformation.
              response_obj = A2A::SendTaskStreamingResponse.new(parsed_data)

              # Yield the parsed response object to the user's block
              block.call(response_obj)

            rescue JSON::ParserError => e
              # Log or raise JSON errors from the stream's data payload
              puts "WARN: JSON Parse Error in stream: #{e.message} - Data: #{data}"
              # raise JSONError, "JSON Parse Error in stream: #{e.message} - Data: #{data}" # Option to raise
            rescue StandardError => e
              # Catch errors within the user's block
              puts "ERROR: Error processing stream event: #{e.message}\n#{e.backtrace.join("\n")}"
              # Re-raise to stop the streaming iteration
              raise StreamingError, "Error processing stream event: #{e.message}"
            end # begin/rescue inside parser block
          end # parser.feed block
        end # response.body.each

      rescue HTTP::Error => e
        # Catch http.rb specific errors (timeouts, connection refused, etc.)
        raise HTTPError, "HTTP Client Error during streaming: #{e.message}"
      rescue StandardError => e
        # Catch other errors (like those raised from the parser block or initial setup)
        # Ensure response is closed if partially read
        response&.connection&.close
        raise StreamingError, "Streaming failed: #{e.message}" unless e.is_a?(StreamingError) || e.is_a?(HTTPError)
        raise # Re-raise if already a handled type
      end
    end


    # --- Private Helper Methods ---
    private

    # Sends a non-streaming request and handles the response.
    # @param request [A2A::JSONRPCRequest] The request object.
    # @return [Hash] The parsed JSON response data (raw hash from JSON parse).
    # @raise [A2A::HTTPError] If there's an HTTP issue.
    # @raise [A2A::JSONError] If the response is not valid JSON.
    # @raise [A2A::RPCError] If the response contains a JSON-RPC error.
    def send_request(request)
      # Use standard headers for non-streaming requests
      http_client = HTTP.timeout(@options[:timeout]).headers(@options[:headers])
      # Send request body with camelCase keys using the URL from the agent card
      response = http_client.post(@url, json: request.to_json_hash)

      unless response.status.success?
        raise HTTPError.new("HTTP Error: #{response.status.code} #{response.status.reason}", response.status.code, response.body.to_s)
      end

      begin
        response_body = response.parse(:json)
        # Return the raw hash parsed from JSON
        response_data = response_body

        # Check for JSON-RPC level error before returning raw hash
        error_info = response_data['error'] || response_data[:error]
        if error_info
          code = error_info['code'] || error_info[:code]
          message = error_info['message'] || error_info[:message] || 'Unknown RPC Error'
          data = error_info['data'] || error_info[:data]
          raise RPCError.new(message, code, message, data)
        end

        response_data # Return the raw hash
      rescue JSON::ParserError => e
        raise JSONError, "JSON Parse Error: #{e.message}"
      rescue HTTP::Error => e # Catch other http gem errors (timeouts, connection issues)
        raise HTTPError, "HTTP Client Error: #{e.message}"
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
        # Use standard JSON accept header
        response = HTTP.headers('Accept' => 'application/json').get(card_url)
        unless response.status.success?
          raise HTTPError.new("Failed to fetch agent card: #{response.status}", response.status.code, response.body.to_s)
        end
        card_data = response.parse(:json)
        # AgentCard.new handles key transformation (camelCase -> snake_case)
        # and raises Dry::Struct::Error if structure is invalid
        AgentCard.new(card_data)
      rescue JSON::ParserError => e
        raise JSONError, "Failed to parse agent card JSON from #{card_url}: #{e.message}"
      rescue HTTP::Error => e
        raise HTTPError, "HTTP error fetching agent card from #{card_url}: #{e.message}"
        # Let Dry::Struct::Error propagate if structure is wrong
      end
    end
  end # class Client
end # module A2A
