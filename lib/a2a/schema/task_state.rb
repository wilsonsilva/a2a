module A2A
  module Schema
    # Task state enum values
    module TaskState
      SUBMITTED = 'submitted'
      WORKING = 'working'
      INPUT_REQUIRED = 'input-required'
      COMPLETED = 'completed'
      CANCELED = 'canceled'
      FAILED = 'failed'
      UNKNOWN = 'unknown'

      ALL_STATES = [
        SUBMITTED,
        WORKING,
        INPUT_REQUIRED,
        COMPLETED,
        CANCELED,
        FAILED,
        UNKNOWN
      ].freeze

      TERMINAL_STATES = [COMPLETED, CANCELED, FAILED].freeze

      # Check if a state is considered terminal
      # @param state [String] The state to check
      # @return [Boolean] True if it's a terminal state
      def self.terminal?(state)
        TERMINAL_STATES.include?(state)
      end
    end
  end
end
