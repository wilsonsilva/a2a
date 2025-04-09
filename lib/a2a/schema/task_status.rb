# frozen_string_literal: true

module A2A
  module Schema
    # Task status representation
    class TaskStatus < SchemaObject
      attr_accessor :state, :message, :timestamp

      # @param state [String] The task state
      # @param message [Message, nil] Optional status message
      # @param timestamp [String, Time, nil] Optional status timestamp
      def initialize(state:, message: nil, timestamp: nil)
        @state = state
        @message = message
        @timestamp = timestamp || Time.now
      end

      REQUIRED_FIELDS = [:state].freeze
    end
  end
end