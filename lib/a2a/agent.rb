# frozen_string_literal: true

module A2A
  # Agent class responsible for defining and managing agent behavior and metadata
  class Agent
    # @return [AgentCard] The agent's metadata card
    # attr_reader :card

    # Creates a new agent instance with the specified card
    #
    # @param card [AgentCard] The agent's metadata card
    def initialize(card = nil)
      @card = card
    end

    # DSL method to define an agent
    #
    # @param block [Proc] Block containing the agent definition
    # @return [Agent] The defined agent instance
    #
    # @example Define an agent using the DSL
    #   agent = A2A::Agent.define do
    #     card do
    #       name 'My Agent'
    #       # ...other card attributes
    #     end
    #   end
    #
    # @example Define an agent with an AgentCard instance
    #   agent = A2A::Agent.define do
    #     card A2A::AgentCard.new(name: 'My Agent', ...)
    #   end
    #
    # @example Define an agent with a JSON file path
    #   agent = A2A::Agent.define do
    #     card 'path/to/agent_card.json'
    #   end
    #
    def self.define(&block)
      new.tap do |agent|
        agent.instance_eval(&block) if block_given?
      end
    end

    # Sets or creates the agent card
    #
    # @param arg [AgentCard, String, nil] The agent card, path to a JSON file, or nil if using block
    # @param block [Proc] Block containing the card definition if arg is nil
    # @return [AgentCard] The agent card instance
    #
    # @raise [AgentCardFileNotFoundError] If the provided card file path does not exist
    #
    def card(arg = nil, &block)
      @card = if arg.is_a?(AgentCard)
                arg
              elsif arg.is_a?(String)
                if File.exist?(arg)
                  AgentCard.from_json(File.read(arg))
                else
                  raise AgentCardFileNotFoundError, arg
                end
              elsif block_given?
                CardBuilder.build(&block)
              else
                @card
              end
    end

    # Helper class to build an AgentCard from a DSL block
    class CardBuilder
      # Builds an AgentCard from the DSL block
      #
      # @param block [Proc] Block containing the card definition
      # @return [AgentCard] The built agent card
      def self.build(&block)
        new.tap do |builder|
          builder.instance_eval(&block)
        end.to_card
      end

      # Initialize with empty attributes hash
      def initialize
        @attributes = {}
        @skills = []
      end

      # Convert the builder to an AgentCard instance
      #
      # @return [AgentCard] The agent card instance
      def to_card
        @attributes[:skills] = @skills unless @skills.empty?
        AgentCard.new(@attributes)
      end

      # Handle method calls for card attributes
      def method_missing(method_name, *args, &block)
        if block_given? && %i[provider capabilities authentication skill].include?(method_name)
          handle_nested_attribute(method_name, &block)
        else
          @attributes[method_name] = args.first
        end
      end

      # Handle nested attributes that require their own builders
      def handle_nested_attribute(attr_name, &block)
        case attr_name
        when :provider
          @attributes[:provider] = ProviderBuilder.build(&block)
        when :capabilities
          @attributes[:capabilities] = CapabilitiesBuilder.build(&block)
        when :authentication
          @attributes[:authentication] = AuthenticationBuilder.build(&block)
        when :skill
          @skills << SkillBuilder.build(&block)
        end
      end

      # Required by Ruby when implementing method_missing
      def respond_to_missing?(method_name, include_private = false)
        true
      end

      # Helper classes for nested attributes

      # Provider Builder class
      class ProviderBuilder
        def self.build(&block)
          new.tap { |builder| builder.instance_eval(&block) }.to_provider
        end

        def initialize
          @attributes = {}
        end

        def to_provider
          AgentProvider.new(@attributes)
        end

        def method_missing(method_name, *args)
          @attributes[method_name] = args.first
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end
      end

      # Capabilities Builder class
      class CapabilitiesBuilder
        def self.build(&block)
          new.tap { |builder| builder.instance_eval(&block) }.to_capabilities
        end

        def initialize
          @attributes = {}
        end

        def to_capabilities
          AgentCapabilities.new(@attributes)
        end

        def method_missing(method_name, *args)
          @attributes[method_name] = args.first
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end
      end

      # Authentication Builder class
      class AuthenticationBuilder
        def self.build(&block)
          new.tap { |builder| builder.instance_eval(&block) }.to_authentication
        end

        def initialize
          @attributes = {}
        end

        def to_authentication
          AgentAuthentication.new(@attributes)
        end

        def method_missing(method_name, *args)
          @attributes[method_name] = args.first
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end
      end

      # Skill Builder class
      class SkillBuilder
        def self.build(&block)
          new.tap { |builder| builder.instance_eval(&block) }.to_skill
        end

        def initialize
          @attributes = {}
        end

        def to_skill
          AgentSkill.new(@attributes)
        end

        def method_missing(method_name, *args)
          @attributes[method_name] = args.first
        end

        def respond_to_missing?(method_name, include_private = false)
          true
        end
      end
    end

    # Error raised when an agent card file is not found
    class AgentCardFileNotFoundError < StandardError
      def initialize(agent_card_path)
        super("Agent card file not found: #{agent_card_path}")
      end
    end
  end
end
