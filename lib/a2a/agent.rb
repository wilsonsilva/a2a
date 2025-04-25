# frozen_string_literal: true

require 'securerandom'

module A2A
  # Agent class responsible for defining and managing agent behavior and metadata
  class Agent
    include DSL

    attr_reader :card, :task_manager

    # Creates a new agent instance with the specified card
    #
    # @param card [AgentCard, nil] The agent's metadata card
    #
    def initialize(card = nil)
      @card = card
      @hooks = {}
      @task_manager = TaskManager.new(self)
    end

    # Registers a hook to be called before task processing
    #
    # @param block [Proc] The hook to be called
    # @return [void]
    #
    def before_task(&block)
      @hooks[:before_task] = block
    end

    # Registers a hook to be called when a task changes state
    #
    # @param block [Proc] The hook to be called
    # @return [void]
    #
    def on_task_transition(&block)
      @hooks[:on_task_transition] = block
    end

    # Registers a hook to be called after task processing
    #
    # @param block [Proc] The hook to be called
    # @return [void]
    #
    def after_task(&block)
      @hooks[:after_task] = block
    end

    # Registers the main task handler
    #
    # @param block [Proc] The task processing logic
    # @return [void]
    #
    def on_task(&block)
      @hooks[:on_task] = block
    end

    # Registers a handler for streaming task responses
    #
    # @param block [Proc] The streaming handler
    # @return [void]
    #
    def on_task_subscribe(&block)
      @hooks[:on_task_subscribe] = block
    end

    # Registers an error handler
    #
    # @param block [Proc] The error handler
    # @return [void]
    #
    def on_error(&block)
      @hooks[:on_error] = block
    end

    # Handle a new or updated task
    # @param task [A2A::Task] The task to handle
    # @return [A2A::Task] The updated task
    def handle_task(task)
      begin
        @hooks[:before_task]&.call(task)

        # Create or update task in task manager
        existing_task = @task_manager.get_task(task.id)

        if existing_task
          # Update existing task
          task = @task_manager.update_task(task)
        else
          # Create new task
          session_id = task.session_id || SecureRandom.uuid
          task = task.with_session_id(session_id)
          task = @task_manager.create_task(task)
        end

        previous_state = existing_task&.status&.state
        current_state = task.status.state

        # Process the task if it's new or requires processing
        if !existing_task || process_task?(previous_state, current_state)
          # Set status to working during processing
          if current_state == 'submitted'
            task = @task_manager.update_task_status(task.id, 'working')
            current_state = 'working'
          end

          # Call the handler based on the specific request
          result = @hooks[:on_task]&.call(task)

          # Update the task with results if any
          if result
            if result.is_a?(A2A::Task)
              task = result
            elsif result.is_a?(Hash)
              # Handle case where result is a hash of update attributes
              task = @task_manager.update_task_attributes(task.id, result)
            elsif result.is_a?(String)
              # Handle case where result is a simple text response
              artifact = create_text_artifact(result)
              task = @task_manager.add_artifact(task.id, artifact)
              task = @task_manager.update_task_status(task.id, 'completed')
            end
          else
            # Default to completing the task if no explicit result returned
            task = @task_manager.update_task_status(task.id, 'completed')
          end
        end

        # Trigger state transition hook if state changed
        if previous_state != current_state
          @hooks[:on_task_transition]&.call(task, previous_state, current_state)
        end

        # Trigger after hook if task is in a terminal state
        if terminal_state?(task.status.state)
          @hooks[:after_task]&.call(task)
        end

        task
      rescue => e
        # Create error task with failed status
        error_task = @task_manager.update_task_status(task.id, 'failed', e.message)
        @hooks[:on_error]&.call(error_task, e)
        error_task
      end
    end

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

    # Get a task by ID
    # @param id [String] Task ID
    # @return [A2A::Task, nil] The task or nil if not found
    def get_task(id)
      @task_manager.get_task(id)
    end

    # Cancel a task by ID
    # @param id [String] Task ID
    # @return [A2A::Task, nil] The updated task or nil if not found
    def cancel_task(id)
      task = @task_manager.get_task(id)
      return nil unless task

      previous_state = task.status.state

      # Only cancel if task isn't already in a terminal state
      unless terminal_state?(previous_state)
        task = @task_manager.update_task_status(id, 'canceled')
        @hooks[:on_task_transition]&.call(task, previous_state, 'canceled')
        @hooks[:after_task]&.call(task)
      end

      task
    end

    # Set push notification configuration for a task
    # @param id [String] Task ID
    # @param config [Hash] Push notification configuration
    # @return [A2A::TaskPushNotificationConfig] The notification config
    def set_push_notification(id, config)
      # Check if push notifications are supported
      unless @card&.capabilities&.push_notifications
        raise UnsupportedOperationError, "Push notifications are not supported by this agent"
      end

      task = @task_manager.get_task(id)
      return nil unless task

      @task_manager.set_push_notification(id, config)
    end

    # Get push notification configuration for a task
    # @param id [String] Task ID
    # @return [A2A::TaskPushNotificationConfig, nil] The notification config or nil
    def get_push_notification(id)
      # Check if push notifications are supported
      unless @card&.capabilities&.push_notifications
        raise UnsupportedOperationError, "Push notifications are not supported by this agent"
      end

      @task_manager.get_push_notification(id)
    end

    # Error raised for unsupported operations
    class UnsupportedOperationError < StandardError; end

    private

    # Determine if a task needs processing based on state transition
    def process_task?(previous_state, current_state)
      return true if previous_state.nil? # New task
      return true if previous_state == 'input-required' && current_state != 'input-required' # User provided input
      false
    end

    # Check if task state is terminal
    def terminal_state?(state)
      %w[completed failed canceled].include?(state)
    end

    # Create a text artifact from a string
    def create_text_artifact(text)
      text_part = A2A::TextPart.new(
        type: 'text',
        text: text,
        metadata: {}
      )

      A2A::Artifact.new(
        parts: [text_part],
        index: 0,
        metadata: {}
      )
    end
  end

  # Task manager to store and manage tasks
  class TaskManager
    def initialize(agent)
      @agent = agent
      @tasks = {}
      @push_notifications = {}
    end

    # Get a task by ID
    def get_task(id)
      @tasks[id]
    end

    # Create a new task
    def create_task(task)
      # Ensure task has an initial status if not provided
      if task.status.nil?
        task = task.with_status(
          A2A::TaskStatus.new(
            state: 'submitted',
            timestamp: Time.now.iso8601
          )
        )
      end

      @tasks[task.id] = task
      task
    end

    # Update an existing task
    def update_task(task)
      existing_task = @tasks[task.id]
      return nil unless existing_task

      @tasks[task.id] = task
      task
    end

    # Update task status
    def update_task_status(id, state, message = nil)
      task = @tasks[id]
      return nil unless task

      status = A2A::TaskStatus.new(
        state: state,
        timestamp: Time.now.iso8601
      )

      if message
        message_part = A2A::TextPart.new(
          type: 'text',
          text: message,
          metadata: {}
        )

        status_message = A2A::Message.new(
          role: 'agent',
          parts: [message_part],
          metadata: {}
        )

        status = status.with_message(status_message)
      end

      task = task.with_status(status)
      @tasks[id] = task

      # Send push notification if configured and in a terminal state
      notify_if_needed(task) if %w[completed failed canceled input-required].include?(state)

      task
    end

    # Update task attributes
    def update_task_attributes(id, attributes)
      task = @tasks[id]
      return nil unless task

      # Apply updates (implementation depends on specific needs)
      # This is a simplified version
      if attributes[:artifacts]
        task = add_artifacts(id, attributes[:artifacts])
      end

      if attributes[:status]
        task = update_task_status(id, attributes[:status])
      end

      task
    end

    # Add an artifact to a task
    def add_artifact(id, artifact)
      task = @tasks[id]
      return nil unless task

      artifacts = task.artifacts || []
      artifacts = artifacts + [artifact]

      task = task.with_artifacts(artifacts)
      @tasks[id] = task
      task
    end

    # Add multiple artifacts to a task
    def add_artifacts(id, artifacts)
      task = @tasks[id]
      return nil unless task

      current_artifacts = task.artifacts || []
      updated_artifacts = current_artifacts + artifacts

      task = task.with_artifacts(updated_artifacts)
      @tasks[id] = task
      task
    end

    # Set push notification config for a task
    def set_push_notification(id, config)
      task = @tasks[id]
      return nil unless task

      push_config = A2A::PushNotificationConfig.new(config.transform_keys(&:to_sym))
      @push_notifications[id] = A2A::TaskPushNotificationConfig.new(
        id: id,
        push_notification_config: push_config
      )
    end

    # Get push notification config for a task
    def get_push_notification(id)
      @push_notifications[id]
    end

    private

    # Send push notification if configured
    def notify_if_needed(task)
      config = @push_notifications[task.id]
      return unless config

      # In a real implementation, this would make an HTTP request
      # to the notification endpoint with proper authentication
      # and the task data

      # For now, just log it
      puts "Would send notification for task #{task.id} to #{config.push_notification_config.url}"
    end
  end
end
