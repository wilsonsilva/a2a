module A2A
  class Agent
    # Error raised when an agent card file is not found
    class AgentCardFileNotFoundError < StandardError
      def initialize(agent_card_path)
        super("Agent card file not found: #{agent_card_path}")
      end
    end
  end
end
