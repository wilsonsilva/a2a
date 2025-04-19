# frozen_string_literal: true

require 'json'
require 'logger'
require 'securerandom'
require 'base64'
require_relative 'transports/rack_transport'
require_relative 'transports/authenticated_rack_transport'
require_relative 'logger'

module A2A
  class Server
    attr_reader :name, :version, :card, :tasks, :capabilities

    DEFAULT_CAPABILITIES = {
      streaming: true,
      pushNotifications: false,
      stateTransitionHistory: true
    }.freeze

    def initialize(name:, version:, logger: A2A::Logger.new, capabilities: {})
      @name = name
      @version = version
      @tasks = {}
      @task_subscriptions = {} # For tracking SSE subscriptions
      @logger = logger
      @logger.level = ::Logger::INFO
      @request_id = 0
      @transport_klass = nil
      @transport = nil
      @capabilities = DEFAULT_CAPABILITIES.dup
      @active_cancellations = Set.new # Track tasks being canceled

      # Merge with provided capabilities
      @capabilities.merge!(capabilities) if capabilities.is_a?(Hash)

      # Initialize the default agent card
      initialize_agent_card
    end
    attr_accessor :transport, :transport_klass, :logger

    # Set or update the agent card
    def set_agent_card(card_data)
      @card = A2A::AgentCard.new(card_data.merge(
        name: @name,
        version: @version,
        capabilities: @capabilities
      ))
    end

    # Register a skill with the server
    def register_skill(skill)
      # Ensure the card exists
      initialize_agent_card if @card.nil?

      # Add the skill to the card
      @card.skills ||= []
      @card.skills << skill
      @logger.info("Registered skill: #{skill.name} (#{skill.id})")
      skill
    end

    # Register multiple skills at once
    def register_skills(*skills)
      skills.each { |skill| register_skill(skill) }
    end

    # Start the server using stdio transport
    def start
      @logger.transport = :stdio
      @logger.info("Starting A2A server: #{@name} v#{@version}")
      @logger.info("Available skills: #{@card.skills.map(&:id).join(', ')}")

      # Use STDIO transport by default
      @transport_klass = A2A::Transports::StdioTransport
      @transport = @transport_klass.new(self, logger: @logger)
      @transport.start
    end

    # Start the server as a Rack middleware
    def start_rack(app, options = {})
      @logger.info("Starting A2A server as Rack middleware: #{@name} v#{@version}")
      @logger.info("Available skills: #{@card.skills.map(&:id).join(', ')}")

      # Use Rack transport
      transport_klass = A2A::Transports::RackTransport
      @transport = transport_klass.new(app, self, options.merge(logger: @logger))
      @transport.start

      # Return the transport as middleware
      @transport
    end

    # Start the server with authentication as a Rack middleware
    def start_authenticated_rack(app, options = {})
      @logger.info("Starting A2A server as Authenticated Rack middleware: #{@name} v#{@version}")
      @logger.info("Available skills: #{@card.skills.map(&:id).join(', ')}")

      # Use Authenticated Rack transport
      transport_klass = A2A::Transports::AuthenticatedRackTransport
      @transport = transport_klass.new(app, self, options.merge(logger: @logger))
      @transport.start

      # Return the transport as middleware
      @transport
    end

    # Handler for incoming JSON-RPC requests
    def handle_request(json_str)
      begin
        request = JSON.parse(json_str)
      rescue JSON::ParserError, TypeError
        return send_error(-32700, 'Invalid JSON payload', nil)
      end

      @logger.debug("Received request: #{request.inspect}")

      # Check if it's a valid JSON-RPC 2.0 request
      unless request['jsonrpc'] == '2.0' && request['method']
        return send_error(-32600, 'Invalid Request', request['id'])
      end

      method = request['method']
      params = request['params'] || {}
      id = request['id']

      case method
      when 'tasks/send'
        handle_tasks_send(params, id)
      when 'tasks/sendSubscribe'
        handle_tasks_send_subscribe(params, id)
      when 'tasks/get'
        handle_tasks_get(params, id)
      when 'tasks/cancel'
        handle_tasks_cancel(params, id)
      when 'tasks/pushNotification/set'
        handle_push_notification_set(params, id)
      when 'tasks/pushNotification/get'
        handle_push_notification_get(params, id)
      when 'tasks/resubscribe'
        handle_tasks_resubscribe(params, id)
      else
        send_error(-32601, "Method not found: #{method}", id)
      end
    rescue StandardError => e
      @logger.error("Error handling request: #{e.message}, #{e.backtrace.join("\n")}")
      send_error(-32603, "Internal error: #{e.message}", id)
    end

    # Process a JSON-RPC request and return the response as a JSON string
    def handle_json_request(request)
      # Process the request
      if request.is_a?(String)
        handle_request(request)
      else
        handle_request(JSON.generate(request))
      end
    end

    # Get a task by ID
    def get_task(task_id)
      task = @tasks[task_id]
      raise "Task not found: #{task_id}" unless task
      task
    end

    # Register a task handler
    def register_task_handler(&block)
      @task_handler = block
    end

    # Check if a task is being canceled
    def task_cancelled?(task_id)
      @active_cancellations.include?(task_id)
    end

    private

    # Initialize the default agent card if none is provided
    def initialize_agent_card
      @card = A2A::AgentCard.new(
        name: @name,
        description: "A2A Server: #{@name}",
        url: "http://localhost:41241", # Default URL
        version: @version,
        capabilities: @capabilities,
        defaultInputModes: ["text"],
        defaultOutputModes: ["text"],
        skills: []
      )
    end

    # Handle tasks/send request
    def handle_tasks_send(params, id)
      task_id = params['id']
      message = params['message']
      session_id = params['sessionId']
      metadata = params['metadata']

      # Validate required parameters
      unless task_id && message && message['role'] && message['parts']
        return send_error(-32602, 'Invalid params: missing required fields', id)
      end

      # Create or update the task
      task = @tasks[task_id] || create_task(task_id, session_id, metadata)

      # Add the message to history
      task.history ||= []
      task.history << message

      # Update task status to working if it was input-required or null
      if task.status.state == 'input-required' || task.status.state == 'submitted'
        task.status.state = 'working'
        task.status.timestamp = Time.now.iso8601
      end

      # Save the updated task
      @tasks[task_id] = task

      # Execute the task handler if registered
      if @task_handler
        begin
          result = @task_handler.call(task, message)

          # Update the task with the result
          if result.is_a?(A2A::Task)
            @tasks[task_id] = result
          else
            # Create a default completed task status if handler didn't return a task
            task.status.state = 'completed'
            task.status.timestamp = Time.now.iso8601
            task.status.message = A2A::Message.new(
              role: 'agent',
              parts: [A2A::TextPart.new(type: 'text', text: 'Task completed')]
            )
          end
        rescue StandardError => e
          @logger.error("Error executing task handler: #{e.message}")
          task.status.state = 'failed'
          task.status.timestamp = Time.now.iso8601
          task.status.message = A2A::Message.new(
            role: 'agent',
            parts: [A2A::TextPart.new(type: 'text', text: "Error: #{e.message}")]
          )
        end
      else
        # No handler registered, return a default response
        task.status.state = 'completed'
        task.status.timestamp = Time.now.iso8601
        task.status.message = A2A::Message.new(
          role: 'agent',
          parts: [A2A::TextPart.new(type: 'text', text: 'No task handler registered')]
        )
      end

      # Return the updated task
      send_result(task, id)
    end

    # Handle tasks/sendSubscribe request (streaming via SSE)
    def handle_tasks_send_subscribe(params, id)
      task_id = params['id']
      message = params['message']
      session_id = params['sessionId']
      metadata = params['metadata']

      # Validate required parameters
      unless task_id && message && message['role'] && message['parts']
        return send_error(-32602, 'Invalid params: missing required fields', id)
      end

      # Check if streaming is supported
      unless @capabilities[:streaming]
        return send_error(-32004, 'Streaming is not supported', id)
      end

      # Create or update the task
      task = @tasks[task_id] || create_task(task_id, session_id, metadata)

      # Add the message to history
      task.history ||= []
      task.history << message

      # Update task status to working
      task.status.state = 'working'
      task.status.timestamp = Time.now.iso8601

      # Save the updated task
      @tasks[task_id] = task

      # Set up streaming response
      stream_setup = {
        id: id,
        task_id: task_id,
        request_id: @request_id += 1
      }

      # Store the subscription for SSE push later
      @task_subscriptions[task_id] ||= []
      @task_subscriptions[task_id] << stream_setup

      # Send initial working status
      send_task_status_update(task_id, task.status, false)

      # Execute task handler asynchronously if registered
      if @task_handler
        Thread.new do
          begin
            handler_result = @task_handler.call(task, message)

            if handler_result.is_a?(A2A::Task)
              @tasks[task_id] = handler_result
              # Send final status update
              send_task_status_update(task_id, handler_result.status, true)
            else
              # Default completion if handler didn't return a task
              task.status.state = 'completed'
              task.status.timestamp = Time.now.iso8601
              # Send final status update
              send_task_status_update(task_id, task.status, true)
            end
          rescue StandardError => e
            @logger.error("Error in streaming task handler: #{e.message}")
            task.status.state = 'failed'
            task.status.timestamp = Time.now.iso8601
            task.status.message = A2A::Message.new(
              role: 'agent',
              parts: [A2A::TextPart.new(type: 'text', text: "Error: #{e.message}")]
            )
            # Send error status
            send_task_status_update(task_id, task.status, true)
          ensure
            # Clean up subscription after task is complete
            @task_subscriptions.delete(task_id)
          end
        end

        # Return immediately without a response body (SSE uses data events)
        return nil
      else
        # No handler registered, return error through stream
        task.status.state = 'failed'
        task.status.timestamp = Time.now.iso8601
        task.status.message = A2A::Message.new(
          role: 'agent',
          parts: [A2A::TextPart.new(type: 'text', text: 'No task handler registered')]
        )

        # Send error through stream
        send_task_status_update(task_id, task.status, true)

        # Clean up subscription
        @task_subscriptions.delete(task_id)

        return nil
      end
    end

    # Handle tasks/get request
    def handle_tasks_get(params, id)
      task_id = params['id']
      history_length = params['historyLength']

      # Validate required parameters
      unless task_id
        return send_error(-32602, 'Invalid params: missing task ID', id)
      end

      # Get the task
      task = @tasks[task_id]
      unless task
        return send_error(-32001, "Task not found: #{task_id}", id)
      end

      # If history length is specified, limit the history
      if history_length && history_length.is_a?(Integer) && history_length >= 0
        if task.history && task.history.length > history_length
          task = task.dup
          task.history = task.history.last(history_length)
        end
      end

      # Return the task
      send_result(task, id)
    end

    # Handle tasks/cancel request
    def handle_tasks_cancel(params, id)
      task_id = params['id']

      # Validate required parameters
      unless task_id
        return send_error(-32602, 'Invalid params: missing task ID', id)
      end

      # Get the task
      task = @tasks[task_id]
      unless task
        return send_error(-32001, "Task not found: #{task_id}", id)
      end

      # Check if task is in a terminal state
      terminal_states = ['completed', 'failed', 'canceled']
      if terminal_states.include?(task.status.state)
        return send_error(-32002, "Task cannot be canceled: already in terminal state #{task.status.state}", id)
      end

      # Mark task as being canceled
      @active_cancellations.add(task_id)

      # Update task status
      task.status.state = 'canceled'
      task.status.timestamp = Time.now.iso8601
      task.status.message = A2A::Message.new(
        role: 'agent',
        parts: [A2A::TextPart.new(type: 'text', text: 'Task canceled by request')]
      )

      # Save the updated task
      @tasks[task_id] = task

      # Notify subscribers if any
      if @task_subscriptions[task_id]
        send_task_status_update(task_id, task.status, true)
        @task_subscriptions.delete(task_id)
      end

      # Remove from active cancellations
      @active_cancellations.delete(task_id)

      # Return the updated task
      send_result(task, id)
    end

    # Handle tasks/pushNotification/set request
    def handle_push_notification_set(params, id)
      # Check if push notifications are supported
      unless @capabilities[:pushNotifications]
        return send_error(-32003, 'Push Notification is not supported', id)
      end

      task_id = params['id']
      push_config = params['pushNotificationConfig']

      # Validate required parameters
      unless task_id && push_config && push_config['url']
        return send_error(-32602, 'Invalid params: missing task ID or push notification config', id)
      end

      # Get the task
      task = @tasks[task_id]
      unless task
        return send_error(-32001, "Task not found: #{task_id}", id)
      end

      # Create the push notification config
      push_notification_config = A2A::TaskPushNotificationConfig.new(
        id: task_id,
        pushNotificationConfig: A2A::PushNotificationConfig.new(push_config)
      )

      # Store the config (in a real implementation, this would be associated with the task)
      task.metadata ||= {}
      task.metadata[:push_notification_config] = push_notification_config

      # Return the config
      send_result(push_notification_config, id)
    end

    # Handle tasks/pushNotification/get request
    def handle_push_notification_get(params, id)
      # Check if push notifications are supported
      unless @capabilities[:pushNotifications]
        return send_error(-32003, 'Push Notification is not supported', id)
      end

      task_id = params['id']

      # Validate required parameters
      unless task_id
        return send_error(-32602, 'Invalid params: missing task ID', id)
      end

      # Get the task
      task = @tasks[task_id]
      unless task
        return send_error(-32001, "Task not found: #{task_id}", id)
      end

      # Get the push notification config if it exists
      push_notification_config = task.metadata && task.metadata[:push_notification_config]
      unless push_notification_config
        return send_error(-32001, "No push notification config found for task: #{task_id}", id)
      end

      # Return the config
      send_result(push_notification_config, id)
    end

    # Handle tasks/resubscribe request
    def handle_tasks_resubscribe(params, id)
      task_id = params['id']

      # Validate required parameters
      unless task_id
        return send_error(-32602, 'Invalid params: missing task ID', id)
      end

      # Check if streaming is supported
      unless @capabilities[:streaming]
        return send_error(-32004, 'Streaming is not supported', id)
      end

      # Get the task
      task = @tasks[task_id]
      unless task
        return send_error(-32001, "Task not found: #{task_id}", id)
      end

      # Set up streaming response
      stream_setup = {
        id: id,
        task_id: task_id,
        request_id: @request_id += 1
      }

      # Store the subscription for SSE push
      @task_subscriptions[task_id] ||= []
      @task_subscriptions[task_id] << stream_setup

      # Send current status immediately
      send_task_status_update(task_id, task.status, task.status.state == 'completed' || task.status.state == 'failed' || task.status.state == 'canceled')

      # If task is in a terminal state, clean up subscription
      terminal_states = ['completed', 'failed', 'canceled']
      if terminal_states.include?(task.status.state)
        @task_subscriptions.delete(task_id)
      end

      # Return immediately without a response body (SSE uses data events)
      return nil
    end

    # Create a new task
    def create_task(task_id, session_id = nil, metadata = nil)
      session_id ||= SecureRandom.uuid

      A2A::Task.new(
        id: task_id,
        sessionId: session_id,
        status: A2A::TaskStatus.new(
          state: 'submitted',
          timestamp: Time.now.iso8601
        ),
        artifacts: [],
        history: [],
        metadata: metadata
      )
    end

    # Send a task status update via SSE
    def send_task_status_update(task_id, status, final = false)
      return unless @task_subscriptions[task_id]

      event = A2A::TaskStatusUpdateEvent.new(
        id: task_id,
        status: status,
        final: final
      )

      @task_subscriptions[task_id].each do |subscription|
        response = {
          jsonrpc: '2.0',
          id: subscription[:id],
          result: event
        }
        @transport.send_sse(JSON.generate(response))
      end
    end

    # Send an artifact update via SSE
    def send_artifact_update(task_id, artifact, final = false)
      return unless @task_subscriptions[task_id]

      event = A2A::TaskArtifactUpdateEvent.new(
        id: task_id,
        artifact: artifact,
        final: final
      )

      @task_subscriptions[task_id].each do |subscription|
        response = {
          jsonrpc: '2.0',
          id: subscription[:id],
          result: event
        }
        @transport.send_sse(JSON.generate(response))
      end
    end

    # Send a JSON-RPC result response
    def send_result(result, id)
      response = {
        jsonrpc: '2.0',
        id: id,
        result: result
      }

      @logger.debug("Sending result: #{response.inspect}")
      send_response(response)
    end

    # Send a JSON-RPC error response
    def send_error(code, message, id = nil)
      response = {
        jsonrpc: '2.0',
        error: {
          code: code,
          message: message
        },
        id: id
      }
      send_response(response)
    end

    # Send a JSON-RPC response
    def send_response(response)
      if @transport
        @logger.debug("Sending response: #{response.inspect}")
        @transport.send_message(response)
      else
        @logger.warn("No transport available to send response: #{response.inspect}")
      end
    end
  end
end
