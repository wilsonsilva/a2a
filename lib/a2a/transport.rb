# frozen_string_literal: true

require 'json'
require 'rack'

module A2A
  # Transport implements a Rack-compatible application for serving A2A protocol
  # Handles HTTP concerns while delegating business logic to the Agent
  class Transport
    CONTENT_TYPE_JSON = 'application/json'
    WELL_KNOWN_PATH = '/.well-known/agent.json'
    DEFAULT_METHODS = %w[tasks/send tasks/get tasks/cancel tasks/sendSubscribe
                        tasks/resubscribe tasks/pushNotification/set tasks/pushNotification/get].freeze

    # @param agent [A2A::Agent] The agent that will handle tasks
    # @param logger [Logger, nil] Optional logger for request/response logging
    def initialize(agent, logger: nil)
      @agent = agent
      @logger = logger
      validate_agent!
    end

    # Rack entry point
    # @param env [Hash] Rack environment
    # @return [Array] Rack response [status, headers, body]
    def call(env)
      request = Rack::Request.new(env)

      log_request(request) if @logger

      response =
        if request.get? && request.path == WELL_KNOWN_PATH
          serve_agent_card
        elsif request.post? && request.path == '/'
          handle_jsonrpc(request)
        else
          [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
        end

      log_response(response) if @logger
      response
    end

    private

    def validate_agent!
      raise ArgumentError, 'Agent must respond to card' unless @agent.respond_to?(:card)
      raise ArgumentError, 'Agent must be able to handle tasks' unless @agent.respond_to?(:handle_task)
    end

    def log_request(request)
      @logger.info("#{request.request_method} #{request.path}")
      @logger.debug("Headers: #{request.env.select { |k, _| k.start_with?('HTTP_') }.inspect}")

      if request.post? && request.content_type == CONTENT_TYPE_JSON
        begin
          body = request.body.read
          request.body.rewind
          @logger.debug("Request body: #{body}")
        rescue => e
          @logger.error("Failed to log request body: #{e.message}")
        end
      end
    end

    def log_response(response)
      status, headers, _ = response
      @logger.info("Response status: #{status}")
      @logger.debug("Response headers: #{headers.inspect}")

      if headers['Content-Type'] == CONTENT_TYPE_JSON && response[2].respond_to?(:each)
        body = ''
        response[2].each { |chunk| body += chunk }
        @logger.debug("Response body: #{body}")
      end
    end

    def serve_agent_card
      body = JSON.generate(@agent.card.to_h)
      [200, { 'Content-Type' => CONTENT_TYPE_JSON }, [body]]
    end

    def handle_jsonrpc(request)
      # Ensure content type is JSON
      unless request.content_type.include?(CONTENT_TYPE_JSON)
        return jsonrpc_error_response(nil, -32600, 'Request payload validation error', 'Content-Type must be application/json')
      end

      # Parse JSON body
      begin
        request_body = request.body.read
        body = JSON.parse(request_body)
      rescue JSON::ParserError
        return jsonrpc_error_response(nil, -32700, 'Invalid JSON payload', 'Request body is not valid JSON')
      end

      # Validate JSON-RPC format
      unless body.is_a?(Hash) && body['jsonrpc'] == '2.0' && body['method'] && body.key?('id')
        return jsonrpc_error_response(nil, -32600, 'Request payload validation error', 'Invalid JSON-RPC format')
      end

      # Route to appropriate method handler
      method = body['method']
      params = body['params'] || {}
      id = body['id']

      case method
      when 'tasks/send'
        handle_send_task(id, params)
      when 'tasks/get'
        handle_get_task(id, params)
      when 'tasks/cancel'
        handle_cancel_task(id, params)
      when 'tasks/sendSubscribe'
        handle_send_subscribe(id, params)
      when 'tasks/resubscribe'
        handle_resubscribe(id, params)
      when 'tasks/pushNotification/set'
        handle_set_push_notification(id, params)
      when 'tasks/pushNotification/get'
        handle_get_push_notification(id, params)
      else
        jsonrpc_error_response(id, -32601, 'Method not found', "Method #{method} is not supported")
      end
    end

    # Handle tasks/send method
    def handle_send_task(id, params)
      task_id = params['id']

      unless task_id
        return jsonrpc_error_response(id, -32602, 'Invalid parameters', 'Task ID is required')
      end

      begin
        # Convert params to task object
        task = build_task_from_params(params)

        # Delegate to agent for business logic
        result = @agent.handle_task(task)

        # Return response
        jsonrpc_success_response(id, result.to_h)
      # rescue => e
      #   jsonrpc_error_response(id, -32603, 'Internal error', e.message)
      end
    end

    # Handle tasks/get method
    def handle_get_task(id, params)
      task_id = params['id']
      history_length = params['historyLength']

      unless task_id
        return jsonrpc_error_response(id, -32602, 'Invalid parameters', 'Task ID is required')
      end

      begin
        task = @agent.get_task(task_id)

        if task.nil?
          return jsonrpc_error_response(id, -32001, 'Task not found', "Task with ID #{task_id} not found")
        end

        # Apply history length limit if specified
        result = task
        if history_length && task.history && !task.history.empty?
          # Get the most recent messages limited by history_length
          limited_history = task.history.last([history_length.to_i, task.history.size].min)
          result = task.copy(history: limited_history)
        end

        jsonrpc_success_response(id, result.to_h)
      rescue => e
        jsonrpc_error_response(id, -32603, 'Internal error', e.message)
      end
    end

    # Handle tasks/cancel method
    def handle_cancel_task(id, params)
      task_id = params['id']

      unless task_id
        return jsonrpc_error_response(id, -32602, 'Invalid parameters', 'Task ID is required')
      end

      begin
        task = @agent.get_task(task_id)

        if task.nil?
          return jsonrpc_error_response(id, -32001, 'Task not found', "Task with ID #{task_id} not found")
        end

        unless task.cancelable?
          return jsonrpc_error_response(id, -32002, 'Task cannot be canceled',
                                        "Task with ID #{task_id} is in state '#{task.status.state}' and cannot be canceled")
        end

        # Cancel the task
        canceled_task = @agent.cancel_task(task_id)

        jsonrpc_success_response(id, canceled_task.to_h)
      rescue => e
        jsonrpc_error_response(id, -32603, 'Internal error', e.message)
      end
    end

    # Handle tasks/sendSubscribe method
    def handle_send_subscribe(id, params)
      # Validate agent supports streaming
      unless @agent.card.capabilities&.streaming
        return jsonrpc_error_response(id, -32004, 'Unsupported operation', 'Streaming is not supported by this agent')
      end

      task_id = params['id']

      unless task_id
        return jsonrpc_error_response(id, -32602, 'Invalid parameters', 'Task ID is required')
      end

      # Implementation would continue with SSE streaming setup
      # This is a placeholder for the actual streaming implementation
      jsonrpc_error_response(id, -32004, 'Unsupported operation', 'Streaming is not fully implemented')
    end

    # Handle tasks/resubscribe method
    def handle_resubscribe(id, params)
      # Validate agent supports streaming
      unless @agent.card.capabilities&.streaming
        return jsonrpc_error_response(id, -32004, 'Unsupported operation', 'Streaming is not supported by this agent')
      end

      task_id = params['id']

      unless task_id
        return jsonrpc_error_response(id, -32602, 'Invalid parameters', 'Task ID is required')
      end

      # Implementation would continue with SSE streaming setup for existing task
      # This is a placeholder for the actual streaming implementation
      jsonrpc_error_response(id, -32004, 'Unsupported operation', 'Streaming is not fully implemented')
    end

    # Helper methods for JSON-RPC responses

    def jsonrpc_success_response(id, result)
      response = {
        jsonrpc: '2.0',
        id: id,
        result: result
      }

      [200, { 'Content-Type' => CONTENT_TYPE_JSON }, [JSON.generate(response)]]
    end

    def jsonrpc_error_response(id, code, message, data = nil)
      error = {
        code: code,
        message: message
      }

      error[:data] = data if data

      response = {
        jsonrpc: '2.0',
        id: id,
        error: error
      }

      [200, { 'Content-Type' => CONTENT_TYPE_JSON }, [JSON.generate(response)]]
    end

    # Convert JSON-RPC params to A2A::Task object
    def build_task_from_params(params)
      # Extract message from params
      message_params = params['message']
      message = message_params ? Message.new(message_params) : nil

      # Extract other relevant fields for task construction
      task_params = {
        id: params['id'],
        session_id: params['sessionId'],
        message: message,
      }

      # If status is provided, use it, otherwise default to 'submitted'
      task_params[:status] = if params['status']
                               TaskStatus.new(params['status'])
                             else
                               TaskStatus.new(state: 'submitted', timestamp: Time.now.iso8601)
                             end

      # Add metadata if present
      task_params[:metadata] = params['metadata'] if params['metadata']

      # Create the task
      Task.new(task_params)
    end
  end
end
