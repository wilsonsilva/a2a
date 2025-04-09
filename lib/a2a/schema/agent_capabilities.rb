# frozen_string_literal: true

module A2A
  module Schema
    # Agent capabilities description
    class AgentCapabilities < SchemaObject
      attr_accessor :streaming, :push_notifications, :state_transition_history

      # @param streaming [Boolean] Whether streaming is supported
      # @param push_notifications [Boolean] Whether push notifications are supported
      # @param state_transition_history [Boolean] Whether state history is supported
      def initialize(streaming: false, push_notifications: false, state_transition_history: false)
        @streaming = streaming
        @push_notifications = push_notifications
        @state_transition_history = state_transition_history
      end

      REQUIRED_FIELDS = [].freeze
    end
  end
end