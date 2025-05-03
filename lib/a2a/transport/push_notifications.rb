# frozen_string_literal: true

module A2A
  class Transport
    module PushNotifications
      # Handle tasks/pushNotification/set method
      def handle_set_push_notification(id, params)
        # Check if agent supports push notifications
        unless @agent.card.capabilities&.push_notifications
          return jsonrpc_error_response(id, -32003, 'Push notifications not supported',
                                        'This agent does not support push notifications')
        end

        task_id = params['id']
        push_config = params['pushNotificationConfig']

        unless task_id && push_config
          return jsonrpc_error_response(id, -32602, 'Invalid parameters',
                                        'Task ID and push notification config are required')
        end

        begin
          task = @agent.get_task(task_id)

          if task.nil?
            return jsonrpc_error_response(id, -32001, 'Task not found',
                                          "Task with ID #{task_id} not found")
          end

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
          return jsonrpc_error_response(id, -32003, 'Push notifications not supported',
                                        'This agent does not support push notifications')
        end

        task_id = params['id']

        unless task_id
          return jsonrpc_error_response(id, -32602, 'Invalid parameters', 'Task ID is required')
        end

        begin
          task = @agent.get_task(task_id)

          if task.nil?
            return jsonrpc_error_response(id, -32001, 'Task not found', "Task with ID #{task_id} not found")
          end

          config = @agent.get_push_notification(task_id)

          if config.nil?
            return jsonrpc_error_response(id, -32001, 'Push notification config not found',
                                          "No push notification config for task ID #{task_id}")
          end

          jsonrpc_success_response(id, config.to_h)
        rescue => e
          jsonrpc_error_response(id, -32603, 'Internal error', e.message)
        end
      end
    end
  end
end
