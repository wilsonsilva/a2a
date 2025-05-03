module A2A
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
