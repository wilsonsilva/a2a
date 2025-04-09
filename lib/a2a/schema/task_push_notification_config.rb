# frozen_string_literal: true

module A2A
  module Schema
    # Task push notification configuration
    class TaskPushNotificationConfig < SchemaObject
      attr_accessor :id, :push_notification_config

      # @param id [String] Task ID
      # @param push_notification_config [PushNotificationConfig] Config details
      def initialize(id:, push_notification_config:)
        @id = id
        @push_notification_config = push_notification_config
      end

      REQUIRED_FIELDS = [:id, :push_notification_config].freeze
    end
  end
end