# frozen_string_literal: true


require_relative '../../lib/a2a'
require_relative 'base_agent'

# Simple echo agent that responds with the user's message
class EchoAgent < BaseAgent
  # Initialize the echo agent
  # @param options [Hash] Additional options
  def initialize(options = {})
    super('Echo Agent', 'An agent that echoes back user messages', options)
  end

  # Process a task by echoing the user's message
  # @param context [TaskContext] The task context
  # @return [Array<Hash>] Array of updates to apply to the task
  def process(context)
    # Extract text from the user message
    user_text = context.user_message.parts
                  .select { |p| p.is_a?(A2A::Schema::TextPart) }
                  .map(&:text)
                  .join(' ')

    # Start with a working response
    updates = [working_response('Processing your message...')]

    # Check for special commands
    if user_text.downcase == 'artifact'
      # Create a text artifact
      updates << create_text_artifact('echo', "You requested an artifact!\n\nThis is the content.")
      updates << completed_response('I created an artifact for you.')
    elsif user_text.downcase == 'input required'
      # Ask for more input
      updates << input_required_response('I need more information. Please provide it.')
    elsif user_text.downcase == 'fail'
      # Simulate an error
      updates << failed_response('You asked me to fail, so I did.')
    else
      # Echo the message back
      updates << completed_response("You said: #{user_text}")
    end

    # binding.irb
    updates
  end
end

EchoAgent.new.start
