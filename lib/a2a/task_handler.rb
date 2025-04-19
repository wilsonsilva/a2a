# frozen_string_literal: true

module A2A
  class TaskHandler
    attr_reader :server

    def initialize(server)
      @server = server
    end

    # Method to be overridden by subclasses
    def call(task, message)
      raise NotImplementedError, "Subclasses must implement the call method"
    end

    # Helper method to create a completed task response
    def completed_task(task, text)
      task = task.dup
      task.status = A2A::TaskStatus.new(
        state: 'completed',
        timestamp: Time.now.iso8601,
        message: A2A::Message.new(
          role: 'agent',
          parts: [A2A::TextPart.new(type: 'text', text: text)]
        )
      )
      task
    end

    # Helper method to create a task that requires user input
    def input_required_task(task, text, form_data = nil)
      task = task.dup
      parts = [A2A::TextPart.new(type: 'text', text: text)]

      # Add form data if provided
      if form_data
        parts << A2A::DataPart.new(type: 'data', data: form_data)
      end

      task.status = A2A::TaskStatus.new(
        state: 'input-required',
        timestamp: Time.now.iso8601,
        message: A2A::Message.new(
          role: 'agent',
          parts: parts
        )
      )
      task
    end

    # Helper method to create a working status update
    def working_task(task, text = "Working on your request...")
      task = task.dup
      task.status = A2A::TaskStatus.new(
        state: 'working',
        timestamp: Time.now.iso8601,
        message: A2A::Message.new(
          role: 'agent',
          parts: [A2A::TextPart.new(type: 'text', text: text)]
        )
      )
      task
    end

    # Helper method to create a failed task response
    def failed_task(task, error_message)
      task = task.dup
      task.status = A2A::TaskStatus.new(
        state: 'failed',
        timestamp: Time.now.iso8601,
        message: A2A::Message.new(
          role: 'agent',
          parts: [A2A::TextPart.new(type: 'text', text: "Error: #{error_message}")]
        )
      )
      task
    end

    # Helper method to add an artifact to a task
    def add_artifact(task, artifact_data)
      task = task.dup
      task.artifacts ||= []

      # Create the new artifact
      artifact = if artifact_data.is_a?(A2A::Artifact)
                   artifact_data
                 else
                   A2A::Artifact.new(artifact_data)
                 end

      # Check if we're updating an existing artifact
      index = artifact.index
      if index && index < task.artifacts.length
        task.artifacts[index] = artifact
      else
        task.artifacts << artifact
      end

      task
    end

    # Helper method to check if task is cancelled
    def cancelled?(task)
      server.task_cancelled?(task.id)
    end

    # Helper method to stream a task artifact
    def stream_artifact(task_id, artifact)
      server.send_artifact_update(task_id, artifact, false)
    end

    # Helper method to stream a status update
    def stream_status(task_id, status, final = false)
      server.send_task_status_update(task_id, status, final)
    end
  end
end
