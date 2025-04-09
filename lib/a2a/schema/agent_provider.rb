# frozen_string_literal: true

module A2A
  module Schema
    # Agent provider information
    class AgentProvider < SchemaObject
      attr_accessor :organization, :url

      # @param organization [String] Organization name
      # @param url [String, nil] Organization URL
      def initialize(organization:, url: nil)
        @organization = organization
        @url = url
      end

      REQUIRED_FIELDS = [:organization].freeze
    end
  end
end