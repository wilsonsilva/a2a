module A2A
  class Agent
    module Streaming
      # Handle a streaming task request
      # @param task [A2A::Task] The task to handle
      # @param stream [Proc] The stream callback
      # @return [Enumerable] Stream of updates
      def handle_task_subscribe(task, stream)
        # Check if streaming is supported
        unless @card&.capabilities&.streaming
          raise UnsupportedOperationError, "Streaming is not supported by this agent"
        end

        # Check if streaming handler is registered
        unless @hooks[:on_task_subscribe]
          raise UnsupportedOperationError, "No streaming handler registered"
        end

        # Process task similar to handle_task, but with streaming
        begin
          @hooks[:before_task]&.call(task)

          # Create or update task
          existing_task = @task_manager.get_task(task.id)

          if existing_task
            task = @task_manager.update_task(task)
          else
            session_id = task.session_id || SecureRandom.uuid
            task = task.with_session_id(session_id)
            task = @task_manager.create_task(task)
          end

          # Call the streaming handler
          @hooks[:on_task_subscribe].call(task, stream)
        rescue => e
          @task_manager.update_task_status(task.id, 'failed', e.message)
          @hooks[:on_error]&.call(task, e)
          raise
        end
      end
    end
  end
end
