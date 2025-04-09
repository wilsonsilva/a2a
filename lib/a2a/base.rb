# frozen_string_literal: true

module A2A
  module Store
    # Base abstract class for task storage providers
    # Implementations must provide both the task and its message history
    class Base
      # Saves a task and its associated message history
      # @param data [Schema::TaskAndHistory] An object containing the task and its history
      # @return [void]
      def save(data)
        raise NotImplementedError, "#{self.class} must implement #save"
      end

      # Loads a task and its history by task ID
      # @param task_id [String] The ID of the task to load
      # @return [Schema::TaskAndHistory, nil] The task and history, or nil if not found
      def load(task_id)
        raise NotImplementedError, "#{self.class} must implement #load"
      end
    end
  end
end
