# frozen_string_literal: true

require 'securerandom'

module A2A
  # Agent class responsible for defining and managing agent behavior and metadata
  class Agent
    module Hooks
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
    end
  end
end
