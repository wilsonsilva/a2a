# frozen_string_literal: true

module A2A
  # Defines the configuration for setting up push notifications for task updates.
  class PushNotificationConfig < ProtocolStruct
    # @return [String, nil] A unique identifier (e.g. UUID) for the push notification configuration, set by the client
    #   to support multiple notification callbacks.
    attribute? :id, Types::String.optional

    # @return [String] The callback URL where the agent should send push notifications.
    attribute :url, Types::String

    # @return [String, nil] A unique token for this task or session to validate incoming push notifications.
    attribute? :token, Types::String.optional

    # @return [PushNotificationAuthenticationInfo, nil] Optional authentication details for the agent to use when
    #   calling the notification URL.
    attribute? :authentication, Types::Constructor(PushNotificationAuthenticationInfo).optional
  end
end
