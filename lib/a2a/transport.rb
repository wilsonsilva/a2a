# frozen_string_literal: true

require 'json'
require 'rack'
require 'rackup'
require 'securerandom'

module A2A
  # Transport class responsible for handling HTTP requests and responses
  # following the A2A protocol. This class is Rack-compatible.
  class Transport
    # Initialize a new Transport instance
    # @param agent [Agent] The agent instance
    # @param task_manager [TaskManager] The task manager instance
    # @param processor [TaskProcessor] The task processor instance
    def initialize(agent, task_manager, processor)
      @agent = agent
      @task_manager = task_manager
      @processor = processor
      @streaming_handlers = {}
    end

    # Rack-compatible call method for handling HTTP requests
    # @param env [Hash] Rack environment
    # @return [Array] Rack-compatible response [status, headers, body]
    def call(env)
      request = Rack::Request.new(env)

      # handle_agent_info(request)
      # when '/v1/task/send'
      # handle_send_task(request)
      # when '/v1/task/send/streaming'
      # handle_send_task_streaming(request)
      # when '/v1/task/:task_id'
      # handle_get_task(request)
      # when '/v1/task/:task_id/cancel'
      # handle_cancel_task(request)
      # when '/v1/task/:task_id/push-notification'
      # handle_push_notification(request)

      case [request.request_method, request.path]
      when ['GET', '/.well-known/agent.json']
        handle_agent_card_request(request)
      when ['POST', '/']
        handle_send_task(request)
      else
        [404, {'Content-Type' => 'application/json'}, ['{"error":"Not Found"}']]
      end

    rescue JSON::ParserError => e
      error_response(Types::JSONParseError.new(e.message))
    # rescue StandardError => e
      # error_response(Types::InternalError.new(e.message))
    end

    private

    # Handle request for agent information
    # @param request [Rack::Request] The HTTP request
    # @return [Array] Rack-compatible response
    def handle_agent_card_request(request)
      # Return agent card information
      [200, { 'Content-Type' => 'application/json' }, [@agent.card.to_json]]
    end

    # Handle request to send a task
    # @param request [Rack::Request] The HTTP request
    # @return [Array] Rack-compatible response
    def handle_send_task(request)
      # Parse request body
      data = JSON.parse(request.body.read, symbolize_names: true)

      # Create task from request parameters
      task_params = data[:params]
      task_id = SecureRandom.uuid

      # Create a new task
      task = Task.new(
        id: task_id,
        params: task_params,
        status: TaskStatus.new(
          # state: TaskState.submitted,
          state: 'submitted',
          message: Message.new(
            parts: [TextPart.new(text: 'Task created')],
            role: 'agent'
          )
        )
      )

      # Store the task
      @task_manager.store_task(task)

      # Begin task processing asynchronously
      @processor.process_async(task)

      # Return the task ID in the response
      response = SendTaskResponse.new(task_id: task_id)
      [200, { 'Content-Type' => 'application/json' }, [response.to_json]]
    end

    # Handle request to send a streaming task
    # @param request [Rack::Request] The HTTP request
    # @return [Array] Rack-compatible response with streaming capability
    def handle_send_task_streaming(request)
      # Parse request body
      data = JSON.parse(request.body.read, symbolize_names: true)

      # Create task from request parameters
      task_params = data[:params]
      task_id = SecureRandom.uuid

      # Create a new task
      task = Task.new(
        id: task_id,
        params: task_params,
        status: TaskStatus.new(
          state: 'submitted',
          message: "Task created"
        ),
        artifacts: []
      )

      # Store the task
      @task_manager.store_task(task)

      # Create streaming response
      streaming_response = Streaming.stream_task(task_id, @processor, @task_manager)

      # Return the streaming response
      [200, streaming_response.headers, streaming_response]
    end

    # Handle request to get a task
    # @param request [Rack::Request] The HTTP request
    # @return [Array] Rack-compatible response
    def handle_get_task(request)
      # Extract task ID from URL
      task_id = extract_task_id_from_path(request.path)

      begin
        # Get the task
        task = @task_manager.get_task(task_id)

        # Return the task in the response
        response = GetTaskResponse.new(task: task)
        [200, { 'Content-Type' => 'application/json' }, [response.to_json]]
      rescue TaskNotFoundError => e
        error_response(e)
      end
    end

    # Handle request to cancel a task
    # @param request [Rack::Request] The HTTP request
    # @return [Array] Rack-compatible response
    def handle_cancel_task(request)
      # Extract task ID from URL
      task_id = extract_task_id_from_path(request.path)

      begin
        # Cancel the task
        task = @task_manager.cancel_task(task_id)

        # Return the updated task in the response
        response = CancelTaskResponse.new(success: true)
        [200, { 'Content-Type' => 'application/json' }, [response.to_json]]
      rescue TaskNotFoundError, TaskNotCancelableError => e
        error_response(e)
      end
    end

    # Handle push notification requests
    # @param request [Rack::Request] The HTTP request
    # @return [Array] Rack-compatible response
    def handle_push_notification(request)
      # Not implemented in this version
      error_response(PushNotificationNotSupportedError.new("Push notifications not supported"))
    end

    # Extract task ID from a URL path
    # @param path [String] The URL path
    # @return [String] The extracted task ID
    def extract_task_id_from_path(path)
      # Extract task ID from a path like "/v1/task/123"
      path.split('/').last
    end

    # Create an error response
    # @param error [StandardError] The error
    # @return [Array] Rack-compatible response
    def error_response(error)
      status_code = 500

      # Set status code based on error type
      if error.is_a?(TaskNotFoundError) || error.is_a?(MethodNotFoundError)
        status_code = 404
      elsif error.is_a?(JSONParseError) || error.is_a?(InvalidParamsError)
        status_code = 400
      elsif error.is_a?(TaskNotCancelableError) || error.is_a?(PushNotificationNotSupportedError)
        status_code = 422
      end

      # Create JSON-RPC style error object
      error_obj = JSONRPCError.new(
        code: error.respond_to?(:code) ? error.code : -32000,
        message: error.message,
        data: nil
      )

      [status_code, { 'Content-Type' => 'application/json' }, [error_obj.to_json]]
    end
  end
end
