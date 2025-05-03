# frozen_string_literal: true

require 'securerandom'

module A2A
  # Agent class responsible for defining and managing agent behavior and metadata
  class Agent
    module PushNotifications
      # Set push notification configuration for a task
      # @param id [String] Task ID
      # @param config [Hash] Push notification configuration
      # @return [A2A::TaskPushNotificationConfig] The notification config
      def set_push_notification(id, config)
        # Check if push notifications are supported
        unless @card&.capabilities&.push_notifications
          raise UnsupportedOperationError, "Push notifications are not supported by this agent"
        end

        task = @task_manager.get_task(id)
        return nil unless task

        @task_manager.set_push_notification(id, config)
      end

      # Get push notification configuration for a task
      # @param id [String] Task ID
      # @return [A2A::TaskPushNotificationConfig, nil] The notification config or nil
      def get_push_notification(id)
        # Check if push notifications are supported
        unless @card&.capabilities&.push_notifications
          raise UnsupportedOperationError, "Push notifications are not supported by this agent"
        end

        @task_manager.get_push_notification(id)
      end
    end
  end
end
