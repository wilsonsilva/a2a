# frozen_string_literal: true

module A2A
  module Schema
    # Push notification configuration
    class PushNotificationConfig < SchemaObject
      attr_accessor :url, :token, :authentication

      # @param url [String] The callback URL
      # @param token [String, nil] Optional token for verification
      # @param authentication [Hash, nil] Optional authentication details
      def initialize(url:, token: nil, authentication: nil)
        @url = url
        @token = token
        @authentication = authentication
      end

      REQUIRED_FIELDS = [:url].freeze
    end
  end
end