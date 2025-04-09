# frozen_string_literal: true

require 'rack'
require 'rack/handler/puma'
require 'rack/contrib'
require 'rack/cors'
require 'json'
require 'time'

module A2A
  # Server implementation for the A2A protocol
  class Server
    # Default options for the server
    DEFAULT_OPTIONS = {
      port: 41241,
      host: '0.0.0.0',
      base_path: '/',
      cors: true,
      store: nil  # Will default to Memory store if nil
    }.freeze

    attr_accessor :card

    # Initialize a new A2A server
    # @param task_handler [Proc] The handler function for tasks
    # @param options [Hash] Server configuration options
    # @option options [Integer] :port (41241) Server port
    # @option options [String] :host ('0.0.0.0') Server host
    # @option options [String] :base_path ('/') Base path for the A2A endpoint
    # @option options [Boolean, Hash] :cors (true) CORS configuration
    # @option options [Store::Base] :store (nil) Task storage implementation
    # @option options [Schema::AgentCard] :card (nil) Agent card
    def initialize(task_handler, options = {})
      @options = DEFAULT_OPTIONS.merge(options)
      @task_handler = task_handler
      @task_store = @options[:store] || Store::Memory.new
      @active_cancellations = Set.new
      @card = @options[:card]

      # Stream management
      @active_streams = {} # Maps task IDs to arrays of connected stream clients
      @stream_mutex = Mutex.new  # Mutex for thread-safe stream operations

      # Normalize base path to start and end with a slash
      @base_path = @options[:base_path]
      @base_path = '/' if @base_path == ''
      @base_path = "/#{@base_path}" unless @base_path.start_with?('/')
      @base_path = "#{@base_path}/" unless @base_path.end_with?('/')
    end

    # Start the server
    # @return [void]
    def start
      puts "A2A Server starting on #{@options[:host]}:#{@options[:port]} at path #{@base_path}"

      # Start the server using Puma
      Rack::Handler::Puma.run(app, Host: @options[:host], Port: @options[:port])
    end

    # Create a Rack application for the server
    # @return [Proc] The Rack application
    def app
      server = self

      Rack::Builder.new do
        # CORS middleware if enabled
        if server.instance_variable_get(:@options)[:cors]
          use Rack::Cors do
            allow do
              origins '*'
              resource '*', headers: :any, methods: [:get, :post]
            end
          end
        end

        # JSON body parser middleware
        use Rack::JSONBodyParser

        # Main application
        run lambda { |env|
          req = Rack::Request.new(env)

          # Agent card endpoint
          if req.path == '/.well-known/agent.json'
            if server.card
              [200, { 'Content-Type' => 'application/json' }, [server.card.to_json]]
            else
              [404, { 'Content-Type' => 'application/json' }, ['{"error":"Agent card not available"}']]
            end
            # A2A protocol endpoint
          elsif req.path == server.instance_variable_get(:@base_path) && req.post?
            # Check for streaming requests
            if req.get_header('HTTP_ACCEPT') == 'text/event-stream'
              server.handle_streaming_request(env, req)
            else
              # Handle regular JSON-RPC requests
              begin
                json_response = server.handle_request(req.params)
                [200, { 'Content-Type' => 'application/json' }, [json_response]]
              rescue Errors::A2AError => e
                error_response = Schema::JSONRPCResponse.new(
                  id: req.params['id'],
                  error: e.to_json_rpc_error
                ).to_json
                [200, { 'Content-Type' => 'application/json' }, [error_response]]
              rescue => e
                # Unexpected errors
                error_response = Schema::JSONRPCResponse.new(
                  id: req.params['id'],
                  error: Schema::JSONRPCError.new(
                    code: Errors::INTERNAL_ERROR,
                    message: "Internal server error: #{e.message}",
                    data: { class: e.class.name, backtrace: e.backtrace&.first(5) }
                  )
                ).to_json
                [200, { 'Content-Type' => 'application/json' }, [error_response]]
              end
            end
          else
            [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
          end
        }
      end
    end

    # Handle streaming requests using SSE
    # @param env [Hash] Rack environment
    # @param req [Rack::Request] The request object
    # @return [Array] Rack response
    def handle_streaming_request(env, req)
      # Parse the request body
      params = req.params

      # Validate JSON-RPC structure
      begin
        validate_json_rpc_request(params)
      rescue Errors::A2AError => e
        error_response = Schema::JSONRPCResponse.new(
          id: params['id'],
          error: e.to_json_rpc_error
        ).to_json
        return [200, { 'Content-Type' => 'application/json' }, [error_response]]
      end

      # Extract basic JSON-RPC fields
      method = params['method']
      id = params['id']
      request_params = params['params']

      # Get task ID from params
      task_id = request_params['id']

      unless task_id
        error_response = Schema::JSONRPCResponse.new(
          id: id,
          error: Errors::A2AError.invalid_params("Missing task ID").to_json_rpc_error
        ).to_json
        return [200, { 'Content-Type' => 'application/json' }, [error_response]]
      end

      # Set up SSE streaming response
      headers = {
        'Content-Type' => 'text/event-stream',
        'Cache-Control' => 'no-cache',
        'Connection' => 'keep-alive'
      }

      # Create a streaming response using Rack Hijack API
      [200, headers, StreamingBody.new(self, task_id, id, method, request_params)]
    end

    # Send an SSE event to all clients connected to a task
    # @param task_id [String] Task ID
    # @param event [Hash] Event data to send
    # @param request_id [String, Integer] Original request ID
    # @return [void]
    def send_sse_event(task_id, event, request_id)
      @stream_mutex.synchronize do
        clients = @active_streams[task_id] || []
        return if clients.empty?

        # Create the JSON-RPC response
        response = Schema::JSONRPCResponse.new(
          id: request_id,
          result: event
        ).to_json

        # Format as SSE event
        sse_data = "data: #{response}\n\n"

        # Send to all connected clients
        clients.each do |client|
          begin
            client.call(sse_data)
          rescue => e
            # If error, remove client
            clients.delete(client)
          end
        end

        # Update clients list or remove if empty
        if clients.empty?
          @active_streams.delete(task_id)
        else
          @active_streams[task_id] = clients
        end
      end
    end

    # Add a new client to a task's stream
    # @param task_id [String] Task ID
    # @param callback [Proc] Callback to send data to client
    # @return [void]
    def add_stream_client(task_id, callback)
      @stream_mutex.synchronize do
        @active_streams[task_id] ||= []
        @active_streams[task_id] << callback
      end
    end

    # Remove a client from a task's stream
    # @param task_id [String] Task ID
    # @param callback [Proc] Client callback to remove
    # @return [void]
    def remove_stream_client(task_id, callback)
      @stream_mutex.synchronize do
        clients = @active_streams[task_id] || []
        clients.delete(callback)

        if clients.empty?
          @active_streams.delete(task_id)
        else
          @active_streams[task_id] = clients
        end
      end
    end

    # Handle an incoming JSON-RPC request
    # @param params [Hash] The request parameters
    # @return [String] The JSON response
    def handle_request(params)
      # Validate JSON-RPC structure
      validate_json_rpc_request(params)

      # Extract basic JSON-RPC fields
      method = params['method']
      id = params['id']
      request_params = params['params']

      # Route based on method
      result = case method
               when 'tasks/send'
                 handle_task_send(request_params, id)
               when 'tasks/sendSubscribe'
                 handle_task_send_subscribe(request_params, id)
               when 'tasks/get'
                 handle_task_get(request_params, id)
               when 'tasks/cancel'
                 handle_task_cancel(request_params, id)
               when 'tasks/pushNotification/set'
                 handle_set_push_notification(request_params, id)
               when 'tasks/pushNotification/get'
                 handle_get_push_notification(request_params, id)
               when 'tasks/resubscribe'
                 handle_task_resubscribe(request_params, id)
               else
                 raise Errors::A2AError.method_not_found(method)
               end

      # Wrap the result in a JSON-RPC response
      Schema::JSONRPCResponse.new(id: id, result: result).to_json
    end

    # === Request Handler Methods ===

    # Handle a tasks/send request
    # @param params [Hash] Request parameters
    # @param id [String] Request ID
    # @return [Schema::Task] The resulting task
    def handle_task_send(params, id)
      validate_task_send_params(params)

      task_id = params['id']
      message = Schema.message_from_hash(params['message'])
      session_id = params['sessionId'] || params['session_id']
      metadata = params['metadata']

      # Load or create task
      task_and_history = load_or_create_task_and_history(task_id, message, session_id, metadata)

      # Create context for the handler
      context = create_task_context(task_and_history.task, message, task_and_history.history)

      # Call the handler
      begin
        result = @task_handler.call(context)

        # If result is an array or enumerable, apply each update
        if result.respond_to?(:each)
          result.each do |update|
            task_and_history = apply_update_to_task_and_history(task_and_history, update)
            @task_store.save(task_and_history)
            context.task = task_and_history.task
          end
        end

        # Return the final task
        task_and_history.task
      rescue => e
        # Apply failure status
        failure_status = {
          'state' => Schema::TaskState::FAILED,
          'message' => {
            'role' => 'agent',
            'parts' => [{ 'text' => "Handler failed: #{e.message}" }]
          }
        }

        task_and_history = apply_update_to_task_and_history(task_and_history, failure_status)
        @task_store.save(task_and_history)

        # Re-raise the error
        raise
      end
    end

    # Handle a tasks/sendSubscribe request (streaming)
    # @param params [Hash] Request parameters
    # @param id [String] Request ID
    # @return [Hash] The initial status event
    def handle_task_send_subscribe(params, id)
      validate_task_send_params(params)

      task_id = params['id']
      message = Schema.message_from_hash(params['message'])
      session_id = params['sessionId'] || params['session_id']
      metadata = params['metadata']

      # Load or create task
      task_and_history = load_or_create_task_and_history(task_id, message, session_id, metadata)

      # Create context for the handler
      context = create_task_context(task_and_history.task, message, task_and_history.history)

      # Start processing in a thread
      Thread.new do
        begin
          # Call the handler and process updates
          @task_handler.call(context).each do |update|
            task_and_history = apply_update_to_task_and_history(task_and_history, update)
            @task_store.save(task_and_history)
            context.task = task_and_history.task

            # Send event to connected clients
            if Utils.task_status_update?(update)
              status = task_and_history.task.status
              is_final = Schema::TaskState.terminal?(status.state)

              event = {
                'id' => task_id,
                'status' => status.to_h,
                'final' => is_final
              }

              send_sse_event(task_id, event, id)

              # If this is a terminal state, we're done
              break if is_final
            elsif Utils.artifact_update?(update)
              # Find the artifact that was just updated
              artifact_index = update['index']
              artifact_name = update['name']

              artifact = nil
              if artifact_index && artifact_index >= 0 && artifact_index < task_and_history.task.artifacts.length
                artifact = task_and_history.task.artifacts[artifact_index]
              elsif artifact_name
                artifact = task_and_history.task.artifacts.find { |a| a.name == artifact_name }
              else
                # If no index or name, assume it's the last one added
                artifact = task_and_history.task.artifacts.last
              end

              next unless artifact

              event = {
                'id' => task_id,
                'artifact' => artifact.to_h,
                'final' => false  # Artifacts never mark the end of a stream
              }

              send_sse_event(task_id, event, id)
            end
          end

          # Ensure we send a final completed state if needed
          if !Schema::TaskState.terminal?(task_and_history.task.status.state)
            # Force to completed state
            complete_update = {
              'state' => Schema::TaskState::COMPLETED,
              'message' => task_and_history.task.status.message&.to_h
            }

            task_and_history = apply_update_to_task_and_history(task_and_history, complete_update)
            @task_store.save(task_and_history)

            # Send final event
            event = {
              'id' => task_id,
              'status' => task_and_history.task.status.to_h,
              'final' => true
            }

            send_sse_event(task_id, event, id)
          end
        rescue => e
          # Apply failure status
          failure_status = {
            'state' => Schema::TaskState::FAILED,
            'message' => {
              'role' => 'agent',
              'parts' => [{ 'text' => "Handler failed: #{e.message}" }]
            }
          }

          task_and_history = apply_update_to_task_and_history(task_and_history, failure_status)
          @task_store.save(task_and_history)

          # Send error event
          event = {
            'id' => task_id,
            'status' => task_and_history.task.status.to_h,
            'final' => true
          }

          send_sse_event(task_id, event, id)
        end
      end

      # Return the initial task status (will be sent immediately in the response)
      {
        'id' => task_id,
        'status' => task_and_history.task.status.to_h,
        'final' => false
      }
    end

    # Handle a tasks/get request
    # @param params [Hash] Request parameters
    # @param id [String] Request ID
    # @return [Schema::Task] The requested task
    def handle_task_get(params, id)
      task_id = params['id']
      raise Errors::A2AError.invalid_params("Missing task ID") unless task_id

      # Load the task
      task_and_history = @task_store.load(task_id)
      raise Errors::A2AError.task_not_found(task_id) unless task_and_history

      # Return the task
      task_and_history.task
    end

    # Handle a tasks/cancel request
    # @param params [Hash] Request parameters
    # @param id [String] Request ID
    # @return [Schema::Task] The canceled task
    def handle_task_cancel(params, id)
      task_id = params['id']
      raise Errors::A2AError.invalid_params("Missing task ID") unless task_id

      # Load the task
      task_and_history = @task_store.load(task_id)
      raise Errors::A2AError.task_not_found(task_id) unless task_and_history

      # Check if cancelable
      if Schema::TaskState.terminal?(task_and_history.task.status.state)
        # Return current state if already in a terminal state
        return task_and_history.task
      end

      # Signal cancellation
      @active_cancellations.add(task_id)

      # Apply canceled state
      cancel_update = {
        'state' => Schema::TaskState::CANCELED,
        'message' => {
          'role' => 'agent',
          'parts' => [{ 'text' => 'Task cancelled by request.' }]
        }
      }

      task_and_history = apply_update_to_task_and_history(task_and_history, cancel_update)
      @task_store.save(task_and_history)

      # Remove from active cancellations
      @active_cancellations.delete(task_id)

      # Send canceled event to any connected streams
      event = {
        'id' => task_id,
        'status' => task_and_history.task.status.to_h,
        'final' => true
      }

      send_sse_event(task_id, event, id)

      # Return the updated task
      task_and_history.task
    end

    # Handle a tasks/pushNotification/set request
    # @param params [Hash] Request parameters
    # @param id [String] Request ID
    # @return [Hash] The confirmed push notification config
    def handle_set_push_notification(params, id)
      # Just return a stub implementation for now
      # In a real implementation, this would register push notification handlers
      raise Errors::A2AError.push_notification_not_supported
    end

    # Handle a tasks/pushNotification/get request
    # @param params [Hash] Request parameters
    # @param id [String] Request ID
    # @return [Hash] The push notification config
    def handle_get_push_notification(params, id)
      # Just return a stub implementation for now
      raise Errors::A2AError.push_notification_not_supported
    end

    # Handle a tasks/resubscribe request
    # @param params [Hash] Request parameters
    # @param id [String] Request ID
    # @return [Hash] The initial status event
    def handle_task_resubscribe(params, id)
      task_id = params['id']
      raise Errors::A2AError.invalid_params("Missing task ID") unless task_id

      # Load the task
      task_and_history = @task_store.load(task_id)
      raise Errors::A2AError.task_not_found(task_id) unless task_and_history

      # Check if task is still in progress
      is_final = Schema::TaskState.terminal?(task_and_history.task.status.state)

      # Start a thread to send any remaining events if task is still in progress
      unless is_final
        Thread.new do
          # Send updates as they occur
          # This would require a more complex implementation with a
          # publisher/subscriber pattern to track task progress
          # For simplicity, we'll just send a working status and then completed

          # Send working status
          sleep 1  # Simulate some processing time
          event = {
            'id' => task_id,
            'status' => {
              'state' => Schema::TaskState::WORKING,
              'timestamp' => Utils.current_timestamp
            },
            'final' => false
          }
          send_sse_event(task_id, event, id)

          # Send completed status
          sleep 2  # More simulated time
          event = {
            'id' => task_id,
            'status' => {
              'state' => Schema::TaskState::COMPLETED,
              'timestamp' => Utils.current_timestamp,
              'message' => {
                'role' => 'agent',
                'parts' => [{ 'text' => 'Task resubscription completed.' }]
              }
            },
            'final' => true
          }
          send_sse_event(task_id, event, id)
        end
      end

      # Return the current status as initial response
      {
        'id' => task_id,
        'status' => task_and_history.task.status.to_h,
        'final' => is_final
      }
    end

    private

    # Validate that a request conforms to JSON-RPC structure
    # @param request [Hash] The request to validate
    # @return [void]
    def validate_json_rpc_request(request)
      # Check basic JSON-RPC structure
      unless request.is_a?(Hash) &&
        request['jsonrpc'] == '2.0' &&
        request['method'].is_a?(String) &&
        !request['method'].empty? &&
        (request['id'].nil? || request['id'].is_a?(String) || request['id'].is_a?(Integer))
        raise Errors::A2AError.invalid_request("Invalid JSON-RPC request structure")
      end
    end

    # Validate parameters for a task send request
    # @param params [Hash] The parameters to validate
    # @return [void]
    def validate_task_send_params(params)
      # Check for required fields
      unless params.is_a?(Hash) && params['id'] && params['message']
        raise Errors::A2AError.invalid_params("Missing or invalid params object")
      end

      # Validate ID
      unless params['id'].is_a?(String) && !params['id'].empty?
        raise Errors::A2AError.invalid_params("Invalid or missing task ID (params.id)")
      end

      # Validate message
      unless params['message'].is_a?(Hash) &&
        params['message']['role'] &&
        params['message']['parts'].is_a?(Array)
        raise Errors::A2AError.invalid_params("Invalid or missing message object (params.message)")
      end
    end

    # Load or create a task and its history
    # @param task_id [String] Task ID
    # @param initial_message [Schema::Message] Initial message
    # @param session_id [String, nil] Optional session ID
    # @param metadata [Hash, nil] Optional metadata
    # @return [Schema::TaskAndHistory] The task and history
    def load_or_create_task_and_history(task_id, initial_message, session_id = nil, metadata = nil)
      data = @task_store.load(task_id)
      needs_save = false

      if data.nil?
        # Create a new task and history
        initial_task = Schema::Task.new(
          id: task_id,
          session_id: session_id,
          status: Schema::TaskStatus.new(
            state: Schema::TaskState::SUBMITTED,
            timestamp: Time.now
          ),
          artifacts: [],
          metadata: metadata
        )

        initial_history = [initial_message]
        data = Schema::TaskAndHistory.new(task: initial_task, history: initial_history)
        needs_save = true
      else
        # Add current message to history
        data = Schema::TaskAndHistory.new(
          task: data.task,
          history: data.history + [initial_message]
        )
        needs_save = true

        # Handle state transitions for existing tasks
        if Schema::TaskState.terminal?(data.task.status.state)
          # Reset state to submitted (keeping history)
          reset_update = {
            'state' => Schema::TaskState::SUBMITTED,
            'message' => nil
          }
          data = apply_update_to_task_and_history(data, reset_update)
        elsif data.task.status.state == Schema::TaskState::INPUT_REQUIRED
          # Change from input-required to working
          working_update = {
            'state' => Schema::TaskState::WORKING
          }
          data = apply_update_to_task_and_history(data, working_update)
        end
      end

      # Save if created or modified
      @task_store.save(data) if needs_save

      data
    end

    # Create a task context for the handler
    # @param task [Schema::Task] The task
    # @param user_message [Schema::Message] The user message
    # @param history [Array<Schema::Message>] Message history
    # @return [TaskContext] The task context
    def create_task_context(task, user_message, history)
      TaskContext.new(
        task: task,
        user_message: user_message,
        history: history,
        is_cancelled: -> { @active_cancellations.include?(task.id) }
      )
    end

    # Apply an update to a task and history
    # @param current [Schema::TaskAndHistory] Current task and history
    # @param update [Hash] The update to apply
    # @return [Schema::TaskAndHistory] Updated task and history
    def apply_update_to_task_and_history(current, update)
      # Deep copy to avoid modifying the original
      new_task = Utils.deep_copy(current.task)
      new_history = Utils.deep_copy(current.history)

      if Utils.task_status_update?(update)
        # Merge status update
        new_status = {
          'state' => update['state'],
          'timestamp' => Utils.current_timestamp
        }

        # Add message if present
        if update['message']
          new_status['message'] = update['message']

          # Add agent message to history
          if update['message']['role'] == 'agent'
            agent_message = Schema.message_from_hash(update['message'])
            new_history << agent_message
          end
        end

        # Update task status
        new_task.status = Schema.task_status_from_hash(new_status)
      elsif Utils.artifact_update?(update)
        # Initialize artifacts array if not present
        new_task.artifacts ||= []

        # Find artifact by index or name if provided
        artifact_index = update['index']
        artifact_name = update['name']
        existing_index = -1

        if artifact_index && artifact_index >= 0 && artifact_index < new_task.artifacts.length
          existing_index = artifact_index
        elsif artifact_name
          new_task.artifacts.each_with_index do |a, i|
            if a.name == artifact_name
              existing_index = i
              break
            end
          end
        end

        # Create the new artifact
        new_artifact = Schema.artifact_from_hash(update)

        if existing_index >= 0
          if update['append']
            # Append to existing artifact
            existing_artifact = new_task.artifacts[existing_index]
            existing_artifact.parts += new_artifact.parts

            # Update metadata if provided
            if new_artifact.metadata
              existing_artifact.metadata ||= {}
              existing_artifact.metadata.merge!(new_artifact.metadata)
            end

            # Update last_chunk flag
            existing_artifact.last_chunk = new_artifact.last_chunk if new_artifact.last_chunk
          else
            # Replace existing artifact
            new_task.artifacts[existing_index] = new_artifact
          end
        else
          # Add as a new artifact
          new_task.artifacts << new_artifact

          # Sort by index if present
          if new_task.artifacts.any? { |a| a.index }
            new_task.artifacts.sort_by! { |a| a.index || 0 }
          end
        end
      end

      Schema::TaskAndHistory.new(task: new_task, history: new_history)
    end
  end

  # Streaming response body for SSE implementation
  class StreamingBody
    # Initialize a new streaming body
    # @param server [Server] The A2A server
    # @param task_id [String] The task ID
    # @param request_id [String, Integer] The original request ID
    # @param method [String] The request method
    # @param params [Hash] The request parameters
    def initialize(server, task_id, request_id, method, params)
      @server = server
      @task_id = task_id
      @request_id = request_id
      @method = method
      @params = params
    end

    # Called by Rack to start the response
    # @param response [Object] The response object
    # @return [void]
    def each(&block)
      # Register the callback to send data
      @server.add_stream_client(@task_id, block)

      # Determine which handler to use based on method
      case @method
      when 'tasks/sendSubscribe'
        # Get initial response
        result = @server.handle_task_send_subscribe(@params, @request_id)

        # Format as SSE event
        json_response = Schema::JSONRPCResponse.new(
          id: @request_id,
          result: result
        ).to_json

        # Send first event
        block.call("data: #{json_response}\n\n")
      when 'tasks/resubscribe'
        # Get initial response
        result = @server.handle_task_resubscribe(@params, @request_id)

        # Format as SSE event
        json_response = Schema::JSONRPCResponse.new(
          id: @request_id,
          result: result
        ).to_json

        # Send first event
        block.call("data: #{json_response}\n\n")
      else
        # Unsupported streaming method
        error = Errors::A2AError.method_not_found(@method)
        error_response = Schema::JSONRPCResponse.new(
          id: @request_id,
          error: error.to_json_rpc_error
        ).to_json

        block.call("data: #{error_response}\n\n")

        # Close the stream
        @server.remove_stream_client(@task_id, block)
      end
    end

    # Called when the client disconnects
    # @return [void]
    def close
      # Remove client from active streams
      @server.remove_stream_client(@task_id, nil)
    end
  end

  # Context object for task handlers
  class TaskContext
    attr_accessor :task, :user_message, :history

    # @param task [Schema::Task] The current task
    # @param user_message [Schema::Message] The user message
    # @param history [Array<Schema::Message>] Message history
    # @param is_cancelled [Proc] Function to check if task is cancelled
    def initialize(task:, user_message:, history:, is_cancelled:)
      @task = task
      @user_message = user_message
      @history = history
      @is_cancelled = is_cancelled
    end

    # Check if the task has been cancelled
    # @return [Boolean] True if the task has been cancelled
    def cancelled?
      @is_cancelled.call
    end
  end
end
