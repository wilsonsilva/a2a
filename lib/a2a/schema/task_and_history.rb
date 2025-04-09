# frozen_string_literal: true

module A2A
  module Schema
    # Task and history combined representation (used internally)
    class TaskAndHistory < SchemaObject
      attr_accessor :task, :history

      # @param task [Task] The task object
      # @param history [Array<Message>] Message history
      def initialize(task:, history:)
        @task = task
        @history = history
      end

      REQUIRED_FIELDS = [:task, :history].freeze
    end
  end
end