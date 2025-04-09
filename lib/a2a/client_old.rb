# frozen_string_literal: true

require 'http'
require 'json'
require 'uri'
require 'securerandom' # For UUID generation

module A2A
  # Base error for client-specific issues
  class ClientError < StandardError; end

  # Error during HTTP communication (network, non-2xx status)
  class HTTPClientError < ClientError
    attr_reader :status_code, :response_body

    def initialize(message, status_code = nil, response_body = nil)
      super(message)
      @status_code = status_code
      @response_body = response_body
    end
  end

  # Error parsing JSON response
  class HTTPJSONError < ClientError
    attr_reader :original_error

    def initialize(message, original_error = nil)
      super(message)
      @original_error = original_error
    end
  end

  # Error reported within the JSON-RPC structure
  class RPCError < ClientError
    attr_reader :code, :rpc_message, :data

    def initialize(code, rpc_message, data = nil)
      super("RPC Error #{code}: #{rpc_message}")
      @code = code
      @rpc_message = rpc_message
      @data = data
    end
  end

  # Client for interacting with an A2A server
  class Client
    attr_reader :base_url, :http_client

    # Initializes the client.
    #
    # @param base_url [String] The base URL of the A2A server endpoint.
    # @param agent_card [A2A::AgentCard, nil] Optional AgentCard to get the URL from.
    # @param http_options [Hash] Options passed directly to the HTTP.persistent client (e.g., :timeout, :ssl_context).
    def initialize(base_url: nil, agent_card: nil, http_options: {})
      unless base_url || agent_card
        raise ArgumentError, 'Must provide either base_url or agent_card'
      end

      @base_url = (agent_card&.url || base_url).chomp('/')
      @http_client = HTTP.persistent(@base_url, **http_options) # Use persistent connection
      @cached_agent_card = agent_card
    end

    # Fetches the AgentCard from the conventional .well-known path.
    # Caches the result.
    #
    # @param agent_card_path [String] The path relative to base_url where the card is hosted.
    # @return [A2A::AgentCard]
    # @raise [A2A::HTTPClientError] if fetching fails.
    # @raise [A2A::HTTPJSONError] if JSON parsing fails.
    def agent_card(agent_card_path: '/.well-known/agent.json')
      return @cached_agent_card if @cached_agent_card

      url = URI.join(@base_url, agent_card_path).to_s
      response = http_client.get(url, headers: { 'Accept' => 'application/json' })

      unless response.status.success?
        raise HTTPClientError.new(
          "Failed to fetch agent card (#{response.status})",
          response.status.code,
          response.body.to_s
        )
      end

      begin
        json_body = JSON.parse(response.body.to_s, symbolize_names: true)
        @cached_agent_card = A2A::AgentCard.new(json_body)
        @cached_agent_card
      rescue JSON::ParserError => e
        raise HTTPJSONError.new("Failed to parse agent card JSON: #{e.message}", e)
      rescue Dry::Struct::Error => e
        raise HTTPJSONError.new("Invalid agent card structure: #{e.message}", e)
      end
    rescue HTTP::Error => e
      raise HTTPClientError.new("HTTP error fetching agent card: #{e.message}")
    end

    # Sends a task request (non-streaming).
    # @param params [Hash] Parameters matching A2A::TaskSendParams structure.
    # @return [A2A::Task, nil] The resulting task object or nil.
    def send_task(params)
      binding.irb
      request = A2A::SendTaskRequest.new(params: A2A::TaskSendParams.new(params))
      perform_request(request, A2A::SendTaskResponse)
    end

    # Retrieves the state of a task.
    # @param params [Hash] Parameters matching A2A::TaskQueryParams structure.
    # @return [A2A::Task, nil] The task object or nil.
    def get_task(params)
      request = A2A::GetTaskRequest.new(params: A2A::TaskQueryParams.new(params))
      perform_request(request, A2A::GetTaskResponse)
    end

    # Cancels a running task.
    # @param params [Hash] Parameters matching A2A::TaskIdParams structure.
    # @return [A2A::Task, nil] The updated task object (usually canceled state) or nil.
    def cancel_task(params)
      request = A2A::CancelTaskRequest.new(params: A2A::TaskIdParams.new(params))
      perform_request(request, A2A::CancelTaskResponse)
    end

    # Sets or updates push notification configuration for a task.
    # @param params [Hash] Parameters matching A2A::TaskPushNotificationConfig structure.
    # @return [A2A::TaskPushNotificationConfig, nil] The confirmed config or nil.
    def set_task_push_notification(params)
      request = A2A::SetTaskPushNotificationRequest.new(params: A2A::TaskPushNotificationConfig.new(params))
      perform_request(request, A2A::SetTaskPushNotificationResponse)
    end

    # Gets the push notification configuration for a task.
    # @param params [Hash] Parameters matching A2A::TaskIdParams structure.
    # @return [A2A::TaskPushNotificationConfig, nil] The current config or nil.
    def get_task_push_notification(params)
      request = A2A::GetTaskPushNotificationRequest.new(params: A2A::TaskIdParams.new(params))
      perform_request(request, A2A::GetTaskPushNotificationResponse)
    end

    # Sends a task and subscribes to streaming updates (SSE).
    # @param params [Hash] Parameters matching A2A::TaskSendParams structure.
    # @yield [A2A::TaskStatusUpdateEvent, A2A::TaskArtifactUpdateEvent] Yields result events from the stream.
    # @return [Enumerator] An enumerator yielding the event results.
    def send_task_subscribe(params)
      request = A2A::SendTaskStreamingRequest.new(params: A2A::TaskSendParams.new(**params))
      perform_streaming_request(request, A2A::SendTaskStreamingResponse)
    end

    # Resubscribes to updates for a task (SSE).
    # @param params [Hash] Parameters matching A2A::TaskQueryParams structure.
    # @yield [A2A::TaskStatusUpdateEvent, A2A::TaskArtifactUpdateEvent] Yields result events from the stream.
    # @return [Enumerator] An enumerator yielding the event results.
    def resubscribe_task(params)
      request = A2A::TaskResubscriptionRequest.new(params: A2A::TaskQueryParams.new(params))
      # Note: The expected response *events* have the same structure as SendTaskStreamingResponse
      perform_streaming_request(request, A2A::SendTaskStreamingResponse)
    end

    # Checks if a capability is likely supported based on the AgentCard.
    # Fetches the card if not already cached.
    # @param capability [Symbol] :streaming or :push_notifications
    # @return [Boolean]
    def supports?(capability)
      card = agent_card # Ensure card is fetched
      case capability
      when :streaming
        !!card.capabilities&.streaming
      when :push_notifications
        !!card.capabilities&.push_notifications
      else
        false
      end
    rescue ClientError => e
      # Log or handle card fetch error? For now, assume false.
      warn "Could not determine support for #{capability} due to error: #{e.message}"
      false
    end

    # Closes the persistent HTTP connection.
    def close
      @http_client.close
    end

    private

    # Generates a unique ID for JSON-RPC requests.
    def generate_request_id
      SecureRandom.uuid
    end

    # Performs a standard JSON-RPC request/response call.
    def perform_request(request_struct, response_class)
      request_struct.id = generate_request_id if request_struct.id.nil?
      request_body = request_struct.to_h.to_json

      response = http_client.post(@base_url, # POST to base URL
                                  headers: {
                                    'Content-Type' => 'application/json',
                                    'Accept' => 'application/json'
                                  },
                                  body: request_body)

      unless response.status.success?
        raise HTTPClientError.new(
          "HTTP Error #{response.status.code} for #{request_struct.method}",
          response.status.code,
          response.body.to_s
        )
      end

      handle_json_response(response.body.to_s, response_class, request_struct.method)
    rescue HTTP::Error => e
      raise HTTPClientError.new("HTTP connection error for #{request_struct.method}: #{e.message}")
    rescue Dry::Struct::Error => e # Handle invalid input params for request structs
      raise ArgumentError, "Invalid parameters for #{request_struct.method}: #{e.message}"
    end

    # Performs a streaming JSON-RPC request via SSE.
    def perform_streaming_request(request_struct, response_class)
      request_struct.id = generate_request_id if request_struct.id.nil?
      request_body = request_struct.to_h.to_json

      # Use an Enumerator to yield results lazily
      Enumerator.new do |yielder|
        buffer = ""
        response = http_client.post(@base_url,
                                    headers: {
                                      'Content-Type' => 'application/json',
                                      'Accept' => 'text/event-stream' # Crucial for SSE
                                    },
                                    body: request_body)

        unless response.status.success?
          raise HTTPClientError.new(
            "HTTP Error #{response.status.code} establishing stream for #{request_struct.method}",
            response.status.code,
            response.body.to_s # Read body only on error
          )
        end

        response.body.each do |chunk|
          buffer << chunk
          # SSE messages are separated by double newlines
          while (separator_index = buffer.index("\n\n"))
            message = buffer.slice!(0, separator_index + 2).strip
            process_sse_message(message, response_class, request_struct.method, yielder)
          end
        end
        # Process any remaining data in the buffer after the stream ends
        process_sse_message(buffer.strip, response_class, request_struct.method, yielder) if buffer && !buffer.strip.empty?

      rescue HTTP::Error => e
        # Re-raise HTTP errors within the Enumerator context if needed,
        # or handle them appropriately (e.g., logging)
        raise HTTPClientError.new("HTTP connection error during stream for #{request_struct.method}: #{e.message}")
      rescue Dry::Struct::Error => e # Handle invalid input params for request structs
        raise ArgumentError, "Invalid parameters for #{request_struct.method}: #{e.message}"
      end
    end

    # Handles parsing and validation of a standard JSON response body.
    def handle_json_response(response_body_str, response_class, method_name)
      begin
        json_data = JSON.parse(response_body_str, symbolize_names: true)
      rescue JSON::ParserError => e
        raise HTTPJSONError.new("Failed to parse JSON response for #{method_name}: #{e.message}", e)
      end

      # Basic JSON-RPC structure check
      unless json_data.is_a?(Hash) && json_data[:jsonrpc] == '2.0'
        raise HTTPJSONError.new("Invalid JSON-RPC structure received for #{method_name}")
      end

      # Check for RPC-level errors
      if (error_data = json_data[:error])
        raise RPCError.new(error_data[:code], error_data[:message], error_data[:data])
      end

      # Instantiate the expected response struct and return the result payload
      begin
        response_struct = response_class.new(json_data)
        response_struct.result
      rescue Dry::Struct::Error => e
        raise HTTPJSONError.new("Invalid response structure for #{method_name}: #{e.message}", e)
      end
    end

    # Processes a single SSE message block.
    def process_sse_message(message_block, response_class, method_name, yielder)
      return if message_block.empty?

      data_lines = []
      message_block.each_line do |line|
        line.strip!
        if line.start_with?('data:')
          data_lines << line.sub(/^data:\s?/, '')
          # else
          # Optionally handle other SSE fields like 'event:', 'id:', 'retry:'
        end
      end

      return if data_lines.empty?

      full_data = data_lines.join("\n") # Reconstruct data if it spanned multiple lines

      begin
        json_data = JSON.parse(full_data, symbolize_names: true)
      rescue JSON::ParserError => e
        warn "[A2A Client Warning] Failed to parse SSE data for #{method_name}: #{e.message}. Data: #{full_data.inspect}"
        return # Skip malformed data
      end

      # Basic JSON-RPC structure check for the event
      unless json_data.is_a?(Hash) && json_data[:jsonrpc] == '2.0'
        warn "[A2A Client Warning] Invalid SSE JSON-RPC structure for #{method_name}. Data: #{json_data.inspect}"
        return
      end

      # Check for RPC-level errors within the event
      if (error_data = json_data[:error])
        # Decide: raise (stops stream) or yield/warn? Raising matches TS client.
        raise RPCError.new(error_data[:code], error_data[:message], error_data[:data])
      end

      # Instantiate response struct and yield the result payload
      begin
        response_struct = response_class.new(json_data)
        yielder << response_struct.result if response_struct.result # Yield only if result is not nil/absent
      rescue Dry::Struct::Error => e
        warn "[A2A Client Warning] Invalid SSE event structure for #{method_name}: #{e.message}. Data: #{json_data.inspect}"
        # Decide: Skip or raise? Skipping allows stream to continue.
      end
    end
  end
end

# Example Usage:
#
# require_relative 'a2a/client'
#
# begin
#   client = A2A::Client.new(base_url: 'http://localhost:8080') # Replace with actual URL
#
#   # Fetch Agent Card (optional but good practice)
#   card = client.agent_card
#   puts "Connected to Agent: #{card.name} v#{card.version}"
#   puts "Supports Streaming: #{client.supports?(:streaming)}"
#
#   # Send a simple task
#   task_id = SecureRandom.uuid
#   task_params = {
#     id: task_id,
#     message: {
#       role: 'user',
#       parts: [{ type: 'text', text: 'Tell me a short story.' }]
#     }
#   }
#
#   if client.supports?(:streaming)
#     puts "Sending task #{task_id} (streaming)..."
#     stream = client.send_task_subscribe(task_params)
#     stream.each do |event|
#       if event.is_a?(A2A::TaskStatusUpdateEvent)
#         puts "Status Update: #{event.status.state}"
#         puts "  Message: #{event.status.message&.parts&.first&.text}" if event.status.message&.parts&.first&.text
#         puts "  Final: #{event.final}"
#       elsif event.is_a?(A2A::TaskArtifactUpdateEvent)
#         puts "Artifact Update:"
#         event.artifact.parts.each { |part| puts "  Part (#{part.type}): #{part.text || part.file || part.data}" }
#       else
#         puts "Received unknown event: #{event.inspect}"
#       end
#     end
#     puts "Streaming finished."
#   else
#      puts "Sending task #{task_id} (non-streaming)..."
#      response_task = client.send_task(task_params)
#      if response_task
#        puts "Task completed: #{response_task.status.state}"
#        response_task.artifacts&.each do |artifact|
#           puts "Artifact:"
#           artifact.parts.each { |part| puts "  Part (#{part.type}): #{part.text || part.file || part.data}" }
#        end
#      else
#        puts "No task result received (might be async)."
#        # Optionally call get_task later
#      end
#   end
#
# rescue A2A::ClientError => e
#   puts "A2A Client Error: #{e.message}"
#   if e.is_a?(A2A::HTTPClientError) && e.response_body
#      puts "  Response Body: #{e.response_body}"
#   elsif e.is_a?(A2A::RPCError)
#      puts "  RPC Data: #{e.data.inspect}" if e.data
#   end
# rescue StandardError => e
#   puts "An unexpected error occurred: #{e.class} - #{e.message}"
#   puts e.backtrace.join("\n")
# ensure
#   client&.close # Close the persistent connection
# end
