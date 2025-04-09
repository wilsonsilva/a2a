# frozen_string_literal: true

module A2A
  module Store
    # File-based implementation of task storage
    class File < Base
      # Initialize a new file store
      # @param options [Hash] Options for the file store
      # @option options [String] :dir Directory to store files (default: '.a2a-tasks')
      def initialize(options = {})
        @base_dir = options[:dir] || '.a2a-tasks'
      end

      # Save a task and its history to files
      # @param data [Schema::TaskAndHistory] The task and history to save
      # @return [void]
      def save(data)
        ensure_directory_exists

        task = data.task
        history = data.history

        task_file_path = get_task_file_path(task.id)
        history_file_path = get_history_file_path(task.id)

        # Write both files
        ::File.write(task_file_path, JSON.generate(task.to_h))
        ::File.write(history_file_path, JSON.generate(message_history: history.map(&:to_h)))

        nil
      end

      # Load a task and its history from files
      # @param task_id [String] The ID of the task to load
      # @return [Schema::TaskAndHistory, nil] The task and history, or nil if not found
      def load(task_id)
        task_file_path = get_task_file_path(task_id)
        history_file_path = get_history_file_path(task_id)

        # Check if task file exists
        return nil unless ::File.exist?(task_file_path)

        # Read and parse task file
        task_data = JSON.parse(::File.read(task_file_path))
        task = Schema.task_from_hash(task_data)

        # Read and parse history file
        history = []
        if ::File.exist?(history_file_path)
          begin
            history_data = JSON.parse(::File.read(history_file_path))
            if history_data.is_a?(Hash) && history_data['messageHistory'].is_a?(Array)
              history = history_data['messageHistory'].map { |msg| Schema.message_from_hash(msg) }
            else
              # Log warning about malformed history file
              warn "Malformed history file for task #{task_id}. Using empty history."
            end
          rescue JSON::ParserError => e
            # Log error reading history file
            warn "Error parsing history file for task #{task_id}: #{e.message}"
          end
        end

        Schema::TaskAndHistory.new(task: task, history: history)
      end

      private

      # Ensure the storage directory exists
      # @return [void]
      def ensure_directory_exists
        FileUtils.mkdir_p(@base_dir) unless ::File.directory?(@base_dir)
      rescue StandardError => e
        raise Errors::A2AError.new(
          Errors::INTERNAL_ERROR,
          "Failed to create directory #{@base_dir}: #{e.message}",
          e
        )
      end

      # Get the file path for a task
      # @param task_id [String] The task ID
      # @return [String] The file path
      def get_task_file_path(task_id)
        # Sanitize task_id to prevent directory traversal
        safe_task_id = ::File.basename(task_id)
        ::File.join(@base_dir, "#{safe_task_id}.json")
      end

      # Get the file path for a task's history
      # @param task_id [String] The task ID
      # @return [String] The file path
      def get_history_file_path(task_id)
        # Sanitize task_id to prevent directory traversal
        safe_task_id = ::File.basename(task_id)
        if safe_task_id != task_id || task_id.include?('..')
          raise Errors::A2AError.invalid_params("Invalid Task ID format: #{task_id}")
        end
        ::File.join(@base_dir, "#{safe_task_id}.history.json")
      end
    end
  end
end
