# frozen_string_literal: true

module A2A
  # Agent class responsible for defining and managing agent behavior and metadata
  class Agent
    include DSL

    # DSL method to define an agent
    #
    # @param block [Proc] Block containing the agent definition
    # @return [Agent] The defined agent instance
    #
    # @example Define an agent using the DSL
    #   agent = A2A::Agent.build do
    #     card do
    #       name 'My Agent'
    #       # ...other card attributes
    #     end
    #   end
    #
    # @example Define an agent with an AgentCard instance
    #   agent = A2A::Agent.build do
    #     card A2A::AgentCard.new(name: 'My Agent', ...)
    #   end
    #
    # @example Define an agent with a JSON file path
    #   agent = A2A::Agent.build do
    #     card 'path/to/agent_card.json'
    #   end
    #
    def self.build(&block)
      DSL.build(&block)
    end

    # Creates a new agent instance with the specified card
    #
    # @param card [AgentCard, nil] The agent's metadata card
    #
    def initialize(card = nil)
      @card = card
    end
  end
end
