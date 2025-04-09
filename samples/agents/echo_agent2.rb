require_relative '../../lib/a2a'
require_relative 'base_agent'

class EchoAgent < BaseAgent
  # Initialize the echo agent
  # @param options [Hash] Additional options
  def initialize(options = {})
    super('Echo Agent', 'An agent that echoes back user messages', options)
  end

  def process(context)
    # Extract user's message
    user_text = context.user_message.parts
                  .select { |p| p.is_a?(A2A::Schema::TextPart) }
                  .map(&:text)
                  .join(' ')

    # Return a completed response with the echoed text
    [completed_response("You said: #{user_text}")]
  end
end

EchoAgent.new(streaming: true).start
