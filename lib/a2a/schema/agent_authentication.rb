# frozen_string_literal: true

module A2A
  module Schema
    # Agent authentication requirements
    class AgentAuthentication < SchemaObject
      attr_accessor :schemes, :credentials

      # @param schemes [Array<String>] Supported auth schemes
      # @param credentials [String, nil] Optional credentials
      def initialize(schemes:, credentials: nil)
        @schemes = schemes
        @credentials = credentials
      end

      REQUIRED_FIELDS = [:schemes].freeze
    end
  end
end