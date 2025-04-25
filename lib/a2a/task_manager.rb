# frozen_string_literal: true

module A2A
  # TaskManager class responsible for managing task lifecycle
  # This includes storing, retrieving, and transitioning task states
  class TaskManager
    # Initialize a new TaskManager
    # @param storage [#get, #set, #delete] (optional) A storage adapter for tasks
    def initialize(storage = nil)
      @storage = storage || InMemoryTaskStorage.new
      @locks = {}
    end

    # Store a new task
    # @param task [Task] The task to store
    # @return [String] The task ID
    def store_task(task)
      @storage.set(task.id, task)
      task.id
    end

    # Retrieve a task by ID
    # @param task_id [String] The ID of the task to retrieve
    # @return [Task, nil] The task if found, nil otherwise
    # @raise [TaskNotFoundError] If the task is not found
    def get_task(task_id)
      task = @storage.get(task_id)
      raise TaskNotFoundError.new(task_id) if task.nil?

      task
    end

    # Update a task's status
    # @param task_id [String] The ID of the task to update
    # @param status [TaskStatus] The new status
    # @return [Task] The updated task
    # @raise [TaskNotFoundError] If the task is not found
    def update_task_status(task_id, status)
      with_task_lock(task_id) do
        task = get_task(task_id)
        binding.irb
        updated_task = task.copy(status: status)
        @storage.set(task_id, updated_task)
        updated_task
      end
    end

    # Add an artifact to a task
    # @param task_id [String] The ID of the task to update
    # @param artifact [Artifact] The artifact to add
    # @return [Task] The updated task
    # @raise [TaskNotFoundError] If the task is not found
    def add_task_artifact(task_id, artifact)
      with_task_lock(task_id) do
        task = get_task(task_id)

        updated_task = task.add_artifact(artifact)

        @storage.set(task_id, updated_task)
        updated_task
      end
    end

    # Cancel a task if it is in a cancelable state
    # @param task_id [String] The ID of the task to cancel
    # @return [Task] The updated task
    # @raise [TaskNotFoundError] If the task is not found
    # @raise [TaskNotCancelableError] If the task cannot be canceled
    def cancel_task(task_id)
      with_task_lock(task_id) do
        task = get_task(task_id)

        raise TaskNotCancelableError.new(task_id) unless task.cancelable?

        cancelled_task = task.cancel('Task was canceled by the client')
        @storage.set(task_id, cancelled_task)
        cancelled_task
      end
    end

    # Delete a task
    # @param task_id [String] The ID of the task to delete
    # @return [Boolean] true if deleted, false otherwise
    def delete_task(task_id)
      @storage.delete(task_id)
      true
    end

    private

    # Execute a block with a lock on a specific task to prevent race conditions
    # @param task_id [String] The ID of the task to lock
    # @yield Block to execute with the lock
    # @return [Object] Result of the block
    def with_task_lock(task_id)
      @locks[task_id] ||= Mutex.new
      @locks[task_id].synchronize do
        yield
      end
    end
  end

  # Default in-memory task storage implementation
  # @private
  class InMemoryTaskStorage
    def initialize
      @tasks = {}
    end

    def get(task_id)
      @tasks[task_id]
    end

    def set(task_id, task)
      @tasks[task_id] = task
    end

    def delete(task_id)
      @tasks.delete(task_id)
    end
  end
end
