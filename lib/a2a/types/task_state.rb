# frozen_string_literal: true

module A2A
  # The current state of the task
  TaskState = Types::String.enum('submitted', 'working', 'input-required', 'completed', 'canceled', 'failed',
                                 'rejected', 'auth-required', 'unknown')
end
