# frozen_string_literal: true

module A2A
  # Defines authentication details for a push notification endpoint.
  class PushNotificationAuthenticationInfo < ProtocolStruct
    # @return [Array<String>] A list of supported authentication schemes (e.g., 'Basic', 'Bearer').
    attribute :schemes, Types::Array.of(Types::String)

    # @return [String, nil] Optional credentials required by the push notification endpoint.
    attribute? :credentials, Types::String.optional
  end
end
