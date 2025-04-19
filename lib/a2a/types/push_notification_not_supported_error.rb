# frozen_string_literal: true

module A2A
  # Error for push notification not supported
  class PushNotificationNotSupportedError < JSONRPCError
    # @return [Integer] Error code (-32003)
    attribute :code, Types::Integer.constant(ErrorCodes::PUSH_NOTIFICATION_NOT_SUPPORTED)

    # @return [String] Error message
    attribute :message, Types::String.constant('Push Notification is not supported')

    # @return [nil] No additional data
    attribute? :data, Types::Nil.constant(nil)
  end
end
