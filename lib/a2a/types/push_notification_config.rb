# frozen_string_literal: true

module A2A
  # Information required for setting up push notifications.
  class PushNotificationConfig < ProtocolStruct
    # @return [String] The URL endpoint where the agent should send notifications.
    attribute :url, Types::String

    # @return [String, nil] A token to be included in push notification requests for verification/authentication.
    attribute? :token, Types::String.optional

    # @return [AuthenticationInfo, nil] Optional authentication details needed by the agent to call the notification URL
    attribute? :authentication, Types::Constructor(AuthenticationInfo).optional
  end
end
