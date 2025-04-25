# frozen_string_literal: true

module A2A
  # TaskProcessor class responsible for handling the task processing pipeline
  # This connects the Agent, TaskManager, and Transport components
  class TaskProcessor
    # Initialize a new TaskProcessor
    # @param agent [Agent] The agent instance
    # @param task_manager [TaskManager] The task manager instance
    def initialize(agent, task_manager)
      @agent = agent
      @task_manager = task_manager
      @handlers = {}
    end

    # Register a handler for a specific message type
    # @param message_type [String] The type of message to handle
    # @param handler [Proc] The handler to execute
    # @return [self] Returns self for method chaining
    def register_handler(message_type, &handler)
      @handlers[message_type] = handler
      self
    end

    # Process a task
    # @param task [Task] The task to process
    # @param callbacks [Hash] Callbacks for streaming events (optional)
    # @option callbacks [Proc] :on_status_update Called when status updates
    # @option callbacks [Proc] :on_artifact_update Called when an artifact is added
    # @return [Task] The processed task
    def process(task, callbacks = {})
      # Update task status to running
      running_status = TaskStatus.new(
        state: 'working',
        message: Message.new(
          parts: [TextPart.new(text: 'Task is processing')],
          role: 'agent'
        )
      )
      task = @task_manager.update_task_status(task.id, running_status)

      # Call status update callback if provided
      callbacks[:on_status_update]&.call(task, running_status)

      begin
        binding.irb
        # Extract message type from task parameters
        message_type = task.params[:type]

        # Find handler for this message type
        handler = @handlers[message_type]

        if handler.nil?
          # No handler found for this message type
          raise UnsupportedOperationError.new("Unsupported message type: #{message_type}")
        end

        # Execute the handler
        result = handler.call(task.params, task)

        # Add result as an artifact if it's not nil
        if result
          artifact = if result.is_a?(Artifact)
                       result
                     else
                       Artifact.new(
                         type: "text",
                         data: {
                           content: result.to_s
                         }
                       )
                     end

          task = @task_manager.add_task_artifact(task.id, artifact)

          # Call artifact update callback if provided
          callbacks[:on_artifact_update]&.call(task, artifact)
        end

        # Update task status to completed
        completed_status = TaskStatus.new(
          state: TaskState::COMPLETED,
          message: "Task completed successfully"
        )
        task = @task_manager.update_task_status(task.id, completed_status)

        # Call status update callback if provided
        callbacks[:on_status_update]&.call(task, completed_status)

      rescue StandardError => e
        # Update task status to failed
        failed_status = TaskStatus.new(
          state: TaskState::FAILED,
          message: "Task failed: #{e.message}"
        )
        task = @task_manager.update_task_status(task.id, failed_status)

        # Call status update callback if provided
        callbacks[:on_status_update]&.call(task, failed_status)
      end

      task
    end

    # Process a task asynchronously
    # @param task [Task] The task to process
    # @param callbacks [Hash] Callbacks for streaming events (optional)
    # @return [Thread] The thread processing the task
    def process_async(task, callbacks = {})
      Thread.new do
        process(task, callbacks)
      end
    end

    # Create a text artifact
    # @param content [String] The text content
    # @return [Artifact] The created artifact
    def self.text_artifact(content)
      Artifact.new(
        type: "text",
        data: {
          content: content.to_s
        }
      )
    end

    # Create a file artifact
    # @param filename [String] The filename
    # @param content [String] The file content
    # @param mime_type [String] The MIME type (defaults to text/plain)
    # @return [Artifact] The created artifact
    def self.file_artifact(filename, content, mime_type = "text/plain")
      Artifact.new(
        type: "file",
        data: {
          filename: filename,
          content: Base64.strict_encode64(content),
          mime_type: mime_type
        }
      )
    end
  end
end
