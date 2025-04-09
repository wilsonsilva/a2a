# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module A2A
  # Client for communicating with A2A protocol servers
  class Client
    # Default headers for JSON-RPC requests
    DEFAULT_HEADERS = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }.freeze

    # Default headers for streaming requests
    STREAMING_HEADERS = {
      'Content-Type' => 'application/json',
      'Accept' => 'text/event-stream'
    }.freeze

    # Custom error class for client-side RPC errors
    class RPCError < StandardError
      attr_reader :code, :data

      # @param code [Integer] Error code
      # @param message [String] Error message
      # @param data [Object, nil] Optional error data
      def initialize(code, message, data = nil)
        super(message)
        @code = code
        @data = data
      end
    end

    # Initialize a new A2A client
    # @param base_url [String] The base URL of the A2A server
    # @param options [Hash] Additional options for the client
    # @option options [Hash] :default_headers Default HTTP headers to use
    # @option options [Integer] :timeout Request timeout in seconds
    def initialize(base_url, options = {})
      # Ensure base URL doesn't end with a slash
      @base_url = base_url.chomp('/')
      @default_headers = options[:default_headers] || {}
      @timeout = options[:timeout] || 60
      @agent_card_cache = nil
    end

    # Fetch the agent card from the server
    # @return [Schema::AgentCard] The agent card
    def agent_card
      return @agent_card_cache if @agent_card_cache

      card_url = "#{@base_url}/.well-known/agent.json"
      response = make_http_request(card_url, Net::HTTP::Get, nil)

      raise RPCError.new(
        Errors::INTERNAL_ERROR,
        "HTTP error #{response.code} fetching agent card: #{response.message}"
      ) unless response.is_a?(Net::HTTPSuccess)

      card_data = JSON.parse(response.body)

      # Would ideally validate the card schema here
      @agent_card_cache = Schema::AgentCard.new(
        name: card_data['name'],
        url: card_data['url'],
        version: card_data['version'],
        capabilities: Schema::AgentCapabilities.new(
          streaming: card_data.dig('capabilities', 'streaming') || false,
          push_notifications: card_data.dig('capabilities', 'pushNotifications') || false,
          state_transition_history: card_data.dig('capabilities', 'stateTransitionHistory') || false
        ),
        skills: (card_data['skills'] || []).map do |skill|
          Schema::AgentSkill.new(
            id: skill['id'],
            name: skill['name'],
            description: skill['description'],
            tags: skill['tags'],
            examples: skill['examples'],
            input_modes: skill['inputModes'],
            output_modes: skill['outputModes']
          )
        end,
        description: card_data['description'],
        provider: card_data['provider'] ? Schema::AgentProvider.new(
          organization: card_data['provider']['organization'],
          url: card_data['provider']['url']
        ) : nil,
        documentation_url: card_data['documentationUrl'],
        authentication: card_data['authentication'] ? Schema::AgentAuthentication.new(
          schemes: card_data['authentication']['schemes'],
          credentials: card_data['authentication']['credentials']
        ) : nil,
        default_input_modes: card_data['defaultInputModes'] || ['text'],
        default_output_modes: card_data['defaultOutputModes'] || ['text']
      )
    end

    # Send a task to the agent (non-streaming)
    # @param params [Schema::TaskSendParams] The parameters for the task
    # @return [Schema::Task, nil] The task object or nil
    def send_task(params)
      response = make_json_rpc_request('tasks/send', params.to_h)
      response ? Schema.task_from_hash(response) : nil
    end

    # Send a task and subscribe to streaming updates
    # @param params [Schema::TaskSendParams] The parameters for the task
    # @yield [Schema::TaskStatusUpdateEvent, Schema::TaskArtifactUpdateEvent] Event updates
    # @return [Enumerator] If no block given, returns an enumerator for the events
    def send_task_subscribe(params)
      return enum_for(:send_task_subscribe, params) unless block_given?

      uri = URI("#{@base_url}")
      req = Net::HTTP::Post.new(uri)
      STREAMING_HEADERS.each { |k, v| req[k] = v }
      @default_headers.each { |k, v| req[k] = v }

      req.body = JSON.generate({
                                 jsonrpc: '2.0',
                                 id: Utils.generate_request_id,
                                 method: 'tasks/sendSubscribe',
                                 params: params.to_h
                               })

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https',
                      open_timeout: @timeout, read_timeout: @timeout) do |http|
        http.request(req) do |response|
          unless response.is_a?(Net::HTTPSuccess)
            raise RPCError.new(Errors::INTERNAL_ERROR,
                               "HTTP error #{response.code}: #{response.message}")
          end

          buffer = ''
          response.read_body do |chunk|
            buffer += chunk
            while (event_end = buffer.index("\n\n"))
              event_data = buffer[0...event_end]
              buffer = buffer[(event_end + 2)..]

              if event_data.start_with?('data: ')
                json_data = event_data['data: '.length..].strip
                parsed_data = JSON.parse(json_data)

                # Check for JSON-RPC error
                if parsed_data['error']
                  error = parsed_data['error']
                  raise RPCError.new(error['code'], error['message'], error['data'])
                end

                # Extract the event from the result
                event = parsed_data['result']

                if event.key?('status')
                  status = Schema.task_status_from_hash(event['status'])
                  yield Schema::TaskStatusUpdateEvent.new(
                    id: event['id'],
                    status: status,
                    final: event['final'] || false,
                    metadata: event['metadata']
                  )
                elsif event.key?('artifact')
                  artifact = Schema.artifact_from_hash(event['artifact'])
                  yield Schema::TaskArtifactUpdateEvent.new(
                    id: event['id'],
                    artifact: artifact,
                    final: event['final'] || false,
                    metadata: event['metadata']
                  )
                end
              end
            end
          end
        end
      end
    end

    # Get a task from the server
    # @param params [Schema::TaskQueryParams] The parameters for the query
    # @return [Schema::Task, nil] The task object or nil
    def get_task(params)
      response = make_json_rpc_request('tasks/get', params.to_h)
      response ? Schema.task_from_hash(response) : nil
    end

    # Cancel a task
    # @param params [Schema::TaskIdParams] The parameters for the cancellation
    # @return [Schema::Task, nil] The updated task or nil
    def cancel_task(params)
      response = make_json_rpc_request('tasks/cancel', params.to_h)
      response ? Schema.task_from_hash(response) : nil
    end

    # Set push notification for a task
    # @param params [Schema::TaskPushNotificationConfig] The push notification config
    # @return [Schema::TaskPushNotificationConfig, nil] The confirmed config or nil
    def set_task_push_notification(params)
      response = make_json_rpc_request('tasks/pushNotification/set', params.to_h)

      if response
        Schema::TaskPushNotificationConfig.new(
          id: response['id'],
          push_notification_config: Schema::PushNotificationConfig.new(
            url: response['pushNotificationConfig']['url'],
            token: response['pushNotificationConfig']['token'],
            authentication: response['pushNotificationConfig']['authentication']
          )
        )
      else
        nil
      end
    end

    # Get push notification config for a task
    # @param params [Schema::TaskIdParams] The parameters for the query
    # @return [Schema::TaskPushNotificationConfig, nil] The notification config or nil
    def get_task_push_notification(params)
      response = make_json_rpc_request('tasks/pushNotification/get', params.to_h)

      if response
        Schema::TaskPushNotificationConfig.new(
          id: response['id'],
          push_notification_config: Schema::PushNotificationConfig.new(
            url: response['pushNotificationConfig']['url'],
            token: response['pushNotificationConfig']['token'],
            authentication: response['pushNotificationConfig']['authentication']
          )
        )
      else
        nil
      end
    end

    # Resubscribe to a task for streaming updates
    # @param params [Schema::TaskQueryParams] The parameters for resubscription
    # @yield [Schema::TaskStatusUpdateEvent, Schema::TaskArtifactUpdateEvent] Event updates
    # @return [Enumerator] If no block given, returns an enumerator for the events
    def resubscribe_task(params)
      return enum_for(:resubscribe_task, params) unless block_given?

      uri = URI("#{@base_url}")
      req = Net::HTTP::Post.new(uri)
      STREAMING_HEADERS.each { |k, v| req[k] = v }
      @default_headers.each { |k, v| req[k] = v }

      req.body = JSON.generate({
                                 jsonrpc: '2.0',
                                 id: Utils.generate_request_id,
                                 method: 'tasks/resubscribe',
                                 params: params.to_h
                               })

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https',
                      open_timeout: @timeout, read_timeout: @timeout) do |http|
        http.request(req) do |response|
          unless response.is_a?(Net::HTTPSuccess)
            raise RPCError.new(Errors::INTERNAL_ERROR,
                               "HTTP error #{response.code}: #{response.message}")
          end

          buffer = ''
          response.read_body do |chunk|
            buffer += chunk
            while (event_end = buffer.index("\n\n"))
              event_data = buffer[0...event_end]
              buffer = buffer[(event_end + 2)..]

              if event_data.start_with?('data: ')
                json_data = event_data['data: '.length..].strip
                parsed_data = JSON.parse(json_data)

                # Check for JSON-RPC error
                if parsed_data['error']
                  error = parsed_data['error']
                  raise RPCError.new(error['code'], error['message'], error['data'])
                end

                # Extract the event from the result
                event = parsed_data['result']

                if event.key?('status')
                  status = Schema.task_status_from_hash(event['status'])
                  yield Schema::TaskStatusUpdateEvent.new(
                    id: event['id'],
                    status: status,
                    final: event['final'] || false,
                    metadata: event['metadata']
                  )
                elsif event.key?('artifact')
                  artifact = Schema.artifact_from_hash(event['artifact'])
                  yield Schema::TaskArtifactUpdateEvent.new(
                    id: event['id'],
                    artifact: artifact,
                    final: event['final'] || false,
                    metadata: event['metadata']
                  )
                end
              end
            end
          end
        end
      end
    end

    # Check if the server supports a specific capability
    # @param capability [Symbol, String] The capability to check (:streaming, :push_notifications)
    # @return [Boolean] True if the capability is supported
    def supports?(capability)
      card = agent_card

      capability_str = capability.to_s
      case capability_str
      when 'streaming'
        !!card.capabilities.streaming
      when 'push_notifications'
        !!card.capabilities.push_notifications
      else
        false
      end
    rescue
      false
    end

    private

    # Make a JSON-RPC request to the server
    # @param method [String] The method name
    # @param params [Hash] The method parameters
    # @return [Hash, nil] The result or nil if an error occurred
    def make_json_rpc_request(method, params)
      request_id = Utils.generate_request_id
      body = {
        jsonrpc: '2.0',
        id: request_id,
        method: method,
        params: params
      }

      response = make_http_request(@base_url, Net::HTTP::Post, JSON.generate(body), DEFAULT_HEADERS)

      unless response.is_a?(Net::HTTPSuccess)
        raise RPCError.new(
          Errors::INTERNAL_ERROR,
          "HTTP error #{response.code}: #{response.message}"
        )
      end

      parsed_response = JSON.parse(response.body)

      if parsed_response['error']
        error = parsed_response['error']
        raise RPCError.new(error['code'], error['message'], error['data'])
      end

      parsed_response['result']
    end

    # Make a basic HTTP request
    # @param url [String] The URL to request
    # @param request_class [Class] The Net::HTTP request class to use
    # @param body [String, nil] The request body
    # @param headers [Hash] Additional headers to include
    # @return [Net::HTTPResponse] The HTTP response
    def make_http_request(url, request_class, body = nil, headers = {})
      uri = URI(url)
      request = request_class.new(uri)

      headers.each { |key, value| request[key] = value }
      @default_headers.each { |key, value| request[key] = value }

      request.body = body if body

      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = @timeout
      http.read_timeout = @timeout

      http.request(request)
    end
  end
end
