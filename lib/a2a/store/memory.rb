# frozen_string_literal: true

module A2A
  module Store
    # Simple in-memory implementation of task storage
    class Memory < Base
      # Initialize a new in-memory store
      def initialize
        @store = {}
      end

      # Save a task and its history to memory
      # @param data [Schema::TaskAndHistory] The task and history to save
      # @return [void]
      def save(data)
        # Store deep copies to prevent external mutation
        @store[data.task.id] = Utils.deep_copy(data)
        nil
      end

      # Load a task and its history from memory
      # @param task_id [String] The ID of the task to load
      # @return [Schema::TaskAndHistory, nil] The task and history, or nil if not found
      def load(task_id)
        entry = @store[task_id]
        # Return a deep copy to prevent external mutation
        entry ? Utils.deep_copy(entry) : nil
      end

      # Clear all tasks from the store
      # @return [void]
      def clear
        @store.clear
        nil
      end

      # Get the number of tasks in the store
      # @return [Integer] The number of tasks
      def size
        @store.size
      end

      # Get all task IDs in the store
      # @return [Array<String>] Array of task IDs
      def task_ids
        @store.keys
      end
    end
  end
end
