# frozen_string_literal: true

# Base class for A2A agents
class BaseAgent
  attr_reader :name, :description, :card

  # Initialize a new agent
  # @param name [String] Agent name
  # @param description [String] Agent description
  # @param options [Hash] Additional options
  def initialize(name, description, options = {})
    @name = name
    @description = description
    @options = options

    # Create agent card
    @card = create_agent_card
  end

  # Process a task
  # @param context [TaskContext] The task context
  # @return [Array<Hash>] Array of updates to apply to the task
  def process(context)
    raise NotImplementedError, "#{self.class} must implement #process"
  end

  # Start the agent server
  # @param port [Integer] Port to listen on
  # @return [void]
  def start(port = 41241)
    # Create server with the agent's handler
    server = A2A::Server.new(
      method(:handle_task),
      port: port,
      card: @card
    )

    # Start the server
    server.start
  end

  protected

  # Create an agent response
  # @param text [String] Response text
  # @param state [String] Task state
  # @return [Hash] Response status update
  def create_response(text, state)
    {
      'state' => state,
      'message' => {
        'role' => 'agent',
        'parts' => [
          { 'text' => text }
        ]
      }
    }
  end

  # Create a working response
  # @param text [String] Response text
  # @return [Hash] Working status update
  def working_response(text)
    create_response(text, A2A::Schema::TaskState::WORKING)
  end

  # Create a completed response
  # @param text [String] Response text
  # @return [Hash] Completed status update
  def completed_response(text)
    create_response(text, A2A::Schema::TaskState::COMPLETED)
  end

  # Create an input-required response
  # @param text [String] Response text
  # @return [Hash] Input-required status update
  def input_required_response(text)
    create_response(text, A2A::Schema::TaskState::INPUT_REQUIRED)
  end

  # Create a failed response
  # @param text [String] Error message
  # @return [Hash] Failed status update
  def failed_response(text)
    create_response(text, A2A::Schema::TaskState::FAILED)
  end

  # Create a text artifact
  # @param name [String] Artifact name
  # @param content [String] Artifact content
  # @param index [Integer, nil] Optional index
  # @return [Hash] Artifact update
  def create_text_artifact(name, content, index = nil)
    {
      'name' => name,
      'parts' => [
        { 'text' => content }
      ],
      'index' => index
    }
  end

  private

  # Task handler function for the server
  # @param context [TaskContext] The task context
  # @return [Array<Hash>] Updates to apply to the task
  def handle_task(context)
    # Call the process method and ensure it returns an array
    result = process(context)
    result.is_a?(Array) ? result : [result]
  rescue => e
    [failed_response("Error processing task: #{e.message}")]
  end

  # Create the agent card
  # @return [A2A::Schema::AgentCard] The agent card
  def create_agent_card
    # Default capabilities
    capabilities = A2A::Schema::AgentCapabilities.new(
      streaming: @options[:streaming] || false,
      push_notifications: @options[:push_notifications] || false,
      state_transition_history: true
    )

    # Default provider
    provider = @options[:provider] || A2A::Schema::AgentProvider.new(
      organization: 'A2A Ruby Agents',
      url: 'https://github.com/username/a2a'
    )

    # Default skills
    skills = @options[:skills] || [
      A2A::Schema::AgentSkill.new(
        id: 'basic_conversation',
        name: 'Basic Conversation',
        description: 'Handle basic conversations with users',
        tags: ['conversation', 'chat']
      )
    ]

    # Create the card
    A2A::Schema::AgentCard.new(
      name: @name,
      description: @description,
      url: @options[:url] || 'http://localhost:41241',
      version: @options[:version] || '0.1.0',
      capabilities: capabilities,
      skills: skills,
      provider: provider,
      documentation_url: @options[:documentation_url],
      authentication: @options[:authentication],
      default_input_modes: @options[:default_input_modes] || ['text'],
      default_output_modes: @options[:default_output_modes] || ['text']
    )
  end
end
