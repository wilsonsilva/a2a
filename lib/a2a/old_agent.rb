# frozen_string_literal: true

require 'securerandom'

module A2A
  # Agent class responsible for defining and managing agent behavior and metadata
  class Agent
    # include Hooks
    include PushNotifications
    include Streaming

    attr_reader :card, :task_manager

    # DSL method to define an agent
    #
    # @param block [Proc] Block containing the agent definition
    # @return [Agent] The defined agent instance
    #
    # @example Define an agent using the DSL
    #   agent = A2A::Agent.build do
    #     card do
    #       name 'My Agent'
    #       # ...other card attributes
    #     end
    #   end
    #
    # @example Define an agent with an AgentCard instance
    #   agent = A2A::Agent.build do
    #     card A2A::AgentCard.new(name: 'My Agent', ...)
    #   end
    #
    # @example Define an agent with a JSON file path
    #   agent = A2A::Agent.build do
    #     card 'path/to/agent_card.json'
    #   end
    #
    def self.build(&block)
      builder = Builder.new
      builder.instance_eval(&block)
      builder.agent
    end

    # Creates a new agent instance with the specified card
    #
    # @param card [AgentCard, nil] The agent's metadata card
    #
    def initialize(card = nil, hooks: {})
      @card = card
      @hooks = hooks
      @task_manager = TaskManager.new(self)
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
        if task.terminal?
          @hooks[:after_task]&.call(task)
        end

        task
      rescue => e
        binding.irb
        # Create error task with failed status
        error_task = @task_manager.update_task_status(task.id, 'failed', e.message)
        @hooks[:on_error]&.call(error_task, e)
        error_task
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
      unless task.terminal?
        task = @task_manager.update_task_status(id, 'canceled')
        @hooks[:on_task_transition]&.call(task, previous_state, 'canceled')
        @hooks[:after_task]&.call(task)
      end

      task
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
end
