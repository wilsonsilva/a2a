# frozen_string_literal: true

module A2A
  module Schema
    # Agent card describing the agent's capabilities
    class AgentCard < SchemaObject
      attr_accessor :name, :description, :url, :provider, :version,
                    :documentation_url, :capabilities, :authentication,
                    :default_input_modes, :default_output_modes, :skills

      # @param name [String] Agent name
      # @param url [String] Agent URL
      # @param version [String] Agent version
      # @param capabilities [AgentCapabilities] Agent capabilities
      # @param skills [Array<AgentSkill>] Agent skills
      # @param description [String, nil] Optional description
      # @param provider [AgentProvider, nil] Optional provider info
      # @param documentation_url [String, nil] Optional docs URL
      # @param authentication [AgentAuthentication, nil] Optional auth details
      # @param default_input_modes [Array<String>, nil] Default input modes
      # @param default_output_modes [Array<String>, nil] Default output modes
      def initialize(name:, url:, version:, capabilities:, skills:,
                     description: nil, provider: nil, documentation_url: nil,
                     authentication: nil, default_input_modes: ['text'],
                     default_output_modes: ['text'])
        @name = name
        @description = description
        @url = url
        @provider = provider
        @version = version
        @documentation_url = documentation_url
        @capabilities = capabilities
        @authentication = authentication
        @default_input_modes = default_input_modes
        @default_output_modes = default_output_modes
        @skills = skills
      end

      REQUIRED_FIELDS = [:name, :url, :version, :capabilities, :skills].freeze
    end
  end
end