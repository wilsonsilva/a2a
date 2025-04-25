# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'json'

module A2A
  # PushNotification module for handling push notifications to external endpoints
  module PushNotification
    # Send a push notification to an external endpoint
    # @param endpoint [String] The URL to send the notification to
    # @param payload [Hash] The payload to send
    # @param config [Types::PushNotificationConfig] Additional configuration
    # @return [Boolean] true if the notification was sent successfully
    # @raise [StandardError] If the notification could not be sent
    def self.send_notification(endpoint, payload, config = nil)
      # Parse the endpoint URL
      uri = URI.parse(endpoint)

      # Create the HTTP request
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri)

      # Set up SSL if using HTTPS
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      # Set headers
      request['Content-Type'] = 'application/json'
      request['User-Agent'] = "A2A Ruby Gem/#{A2A::VERSION}"

      # Add authorization if provided
      if config&.authentication
        case config.authentication.type
        when 'bearer'
          request['Authorization'] = "Bearer #{config.authentication.token}"
        when 'basic'
          request.basic_auth(config.authentication.username, config.authentication.password)
        end
      end

      # Set the request body
      request.body = payload.to_json

      # Send the request
      response = http.request(request)

      # Raise an error if the request was not successful
      unless response.code.to_i.between?(200, 299)
        raise "Push notification failed with status #{response.code}: #{response.body}"
      end

      true
    end

    # TaskNotificationManager class for managing task push notifications
    class TaskNotificationManager
      # Initialize a new TaskNotificationManager
      def initialize
        @configurations = {}
        @mutex = Mutex.new
      end

      # Set a push notification configuration for a task
      # @param task_id [String] The task ID
      # @param config [Types::TaskPushNotificationConfig] The push notification configuration
      # @return [Boolean] true if the configuration was set successfully
      def set_config(task_id, config)
        @mutex.synchronize do
          @configurations[task_id] = config
        end
        true
      end

      # Get the push notification configuration for a task
      # @param task_id [String] The task ID
      # @return [Types::TaskPushNotificationConfig, nil] The push notification configuration
      def get_config(task_id)
        @mutex.synchronize do
          @configurations[task_id]
        end
      end

      # Remove the push notification configuration for a task
      # @param task_id [String] The task ID
      # @return [Boolean] true if the configuration was removed successfully
      def remove_config(task_id)
        @mutex.synchronize do
          @configurations.delete(task_id)
        end
        true
      end

      # Send a task status update notification
      # @param task [Types::Task] The task
      # @return [Boolean] true if the notification was sent successfully
      def notify_status_update(task)
        config = get_config(task.id)
        return false unless config&.status_updates_url

        # Create notification payload
        event = TaskStatusUpdateEvent.new(
          task_id: task.id,
          status: task.status
        )

        # Send the notification
        PushNotification.send_notification(
          config.status_updates_url,
          event,
          config
        )
      end

      # Send a task artifact update notification
      # @param task [Types::Task] The task
      # @param artifact [Types::Artifact] The artifact
      # @return [Boolean] true if the notification was sent successfully
      def notify_artifact_update(task, artifact)
        config = get_config(task.id)
        return false unless config&.artifact_updates_url

        # Create notification payload
        event = Types::TaskArtifactUpdateEvent.new(
          task_id: task.id,
          artifact: artifact
        )

        # Send the notification
        PushNotification.send_notification(
          config.artifact_updates_url,
          event,
          config
        )
      end
    end
  end
end
