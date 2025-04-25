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

    def initialize(agent)
      @agent = agent
      validate_agent!
    end

    # Rack entry point
    def call(env)
      request = Rack::Request.new(env)

      # Handle well-known agent card path
      if request.get? && request.path == WELL_KNOWN_PATH
        return serve_agent_card
      end

      # Handle JSON-RPC requests
      if request.post? && request.path == '/'
        return handle_jsonrpc(request)
      end

      # Any other path returns 404
      [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
    end

    private

    def validate_agent!
      raise ArgumentError, 'Agent must respond to card' unless @agent.respond_to?(:card)
      raise ArgumentError, 'Agent must respond to handle_task' unless @agent.respond_to?(:handle_task)
    end

    def serve_agent_card
      body = JSON.generate(@agent.card.to_h)
      [200, { 'Content-Type' => CONTENT_TYPE_JSON }, [body]]
    end

    def handle_jsonrpc(request)
      # Ensure content type is JSON
      unless request.content_type == CONTENT_TYPE_JSON
        return jsonrpc_error_response(-32600, 'Request payload validation error', 'Content-Type must be application/json')
      end

      # Parse JSON body
      begin
        body = JSON.parse(request.body.read)
      rescue JSON::ParserError
        return jsonrpc_error_response(-32700, 'Invalid JSON payload', 'Request body is not valid JSON')
      end

      # Validate JSON-RPC format
      unless body.is_a?(Hash) && body['jsonrpc'] == '2.0' && body['method'] && body.key?('id')
        return jsonrpc_error_response(-32600, 'Request payload validation error', 'Invalid JSON-RPC format')
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
        jsonrpc_error_response(-32601, 'Method not found', "Method #{method} is not supported")
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
      rescue => e
        jsonrpc_error_response(id, -32603, 'Internal error', e.message)
      end
    end

    # Handle tasks/get method
    def handle_get_task(id, params)
      task_id = params['id']

      unless task_id
        return jsonrpc_error_response(id, -32602, 'Invalid parameters', 'Task ID is required')
      end

      begin
        task = @agent.get_task(task_id)

        if task.nil?
          return jsonrpc_error_response(id, -32001, 'Task not found', "Task with ID #{task_id} not found")
        end

        jsonrpc_success_response(id, task.to_h)
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
        task = @agent.cancel_task(task_id)

        if task.nil?
          return jsonrpc_error_response(id, -32001, 'Task not found', "Task with ID #{task_id} not found")
        end

        jsonrpc_success_response(id, task.to_h)
      rescue => e
        jsonrpc_error_response(id, -32603, 'Internal error', e.message)
      end
    end

    # Handle tasks/sendSubscribe method (stub for future implementation)
    def handle_send_subscribe(id, params)
      # This would implement SSE streaming in the future
      # For now, return error indicating lack of support
      jsonrpc_error_response(id, -32004, 'This operation is not supported', 'Streaming is not supported by this agent')
    end

    # Handle tasks/resubscribe method (stub for future implementation)
    def handle_resubscribe(id, params)
      # This would implement SSE streaming in the future
      # For now, return error indicating lack of support
      jsonrpc_error_response(id, -32004, 'This operation is not supported', 'Streaming is not supported by this agent')
    end

    # Handle tasks/pushNotification/set method
    def handle_set_push_notification(id, params)
      # Check if agent supports push notifications
      unless @agent.card.capabilities&.push_notifications
        return jsonrpc_error_response(id, -32003, 'Push notifications not supported', 'This agent does not support push notifications')
      end

      task_id = params['id']
      push_config = params['pushNotificationConfig']

      unless task_id && push_config
        return jsonrpc_error_response(id, -32602, 'Invalid parameters', 'Task ID and push notification config are required')
      end

      begin
        result = @agent.set_push_notification(task_id, push_config)
        jsonrpc_success_response(id, result.to_h)
      rescue => e
        jsonrpc_error_response(id, -32603, 'Internal error', e.message)
      end
    end

    # Handle tasks/pushNotification/get method
    def handle_get_push_notification(id, params)
      # Check if agent supports push notifications
      unless @agent.card.capabilities&.push_notifications
        return jsonrpc_error_response(id, -32003, 'Push notifications not supported', 'This agent does not support push notifications')
      end

      task_id = params['id']

      unless task_id
        return jsonrpc_error_response(id, -32602, 'Invalid parameters', 'Task ID is required')
      end

      begin
        config = @agent.get_push_notification(task_id)

        if config.nil?
          return jsonrpc_error_response(id, -32001, 'Task not found', "Task with ID #{task_id} not found")
        end

        jsonrpc_success_response(id, config.to_h)
      rescue => e
        jsonrpc_error_response(id, -32603, 'Internal error', e.message)
      end
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
      # This would convert the params hash to an A2A::Task instance
      # Implementation depends on dry-struct definitions
      # This is a simplified version
      task_params = params.transform_keys(&:to_sym)
      A2A::Task.new(task_params)
    end
  end
end
