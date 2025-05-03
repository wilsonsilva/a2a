# frozen_string_literal: true

require_relative '../lib/a2a'
require 'rack'
require 'rackup/handler/webrick'
require 'logger'

# Create a logger for the agent
logger = Logger.new($stdout)
logger.level = Logger::INFO

# Create a basic echo agent
echo_agent = A2A::Agent.build do
  card do
    name 'Echo Agent'
    description 'A simple agent that echoes back user messages'
    url 'http://localhost:9292'
    version '1.0.0'

    capabilities do
      streaming false
      push_notifications false
      state_transition_history false
    end

    skill 'echo' do
      name 'Echo'
      description 'Echoes back any message sent'
      tags ['echo', 'repeat', 'mirror']
      examples ['Hello, can you repeat this?', 'Echo: testing 1, 2, 3']
      input_modes ['text/plain']
      output_modes ['text/plain']
    end
  end

  # Log when tasks are received
  before_task do |task|
    logger.info("Received task: #{task.id}")
  end

  # Log state transitions
  on_task_transition do |task, from, to|
    logger.info("Task #{task.id} state changed: #{from || 'new'} -> #{to}")
  end

  # Log when tasks are completed
  after_task do |task|
    logger.info("Task completed: #{task.id}")
  end

  # This is where the actual work happens
  on_task do |task|
    # Extract text from the first part of the message
    if task.message && task.message.parts && !task.message.parts.empty?
      part = task.message.parts.first

      if part.type == 'text'
        input_text = part.text
        echo_text = "Echo: #{input_text}"
        logger.info("Echoing: #{input_text}")

        # Create a response artifact
        part = A2A::TextPart.new(
          type: 'text',
          text: echo_text,
          metadata: {}
        )

        artifact = A2A::Artifact.new(
          parts: [part],
          index: 0,
          metadata: {}
        )

        # Create a response message
        message = A2A::Message.new(
          role: 'agent',
          parts: [part],
          metadata: {}
        )

        # Create a task status
        status = A2A::TaskStatus.new(
          state: 'completed',
          message: message,
          timestamp: Time.now.iso8601
        )

        # Return updated task - Note: immutable objects pattern
        task = task.copy(
          artifacts: [artifact],
          status: status
        )

        logger.debug("Returning task with #{task.artifacts.size} artifacts")
        task
      else
        # Create an error response for non-text input
        message = A2A::Message.new(
          role: 'agent',
          parts: [A2A::TextPart.new(
            type: 'text',
            text: "Sorry, I can only echo text messages",
            metadata: {}
          )],
          metadata: {}
        )

        status = A2A::TaskStatus.new(
          state: 'failed',
          message: message,
          timestamp: Time.now.iso8601
        )

        logger.warn("Received non-text message: #{part.type}")
        task.copy(status: status)
      end
    else
      # Create an error response for empty message
      message = A2A::Message.new(
        role: 'agent',
        parts: [A2A::TextPart.new(
          type: 'text',
          text: "No message content found to echo",
          metadata: {}
        )],
        metadata: {}
      )

      status = A2A::TaskStatus.new(
        state: 'failed',
        message: message,
        timestamp: Time.now.iso8601
      )

      logger.warn("Received empty message")
      task.copy(status: status)
    end
  end

  # Handle errors
  on_error do |task, error|
    logger.error("Error processing task #{task.id}: #{error.message}")
    logger.error(error.backtrace.join("\n"))
  end
end

# Create a Rack application
app = A2A::Transport.new(echo_agent, logger: logger)

# Run with Rackup when this file is executed directly
if __FILE__ == $0
  logger.info("Starting Echo Agent server...")

  # Set up signal handling for graceful shutdown
  trap('INT') do
    logger.info("Shutting down...")
    exit
  end

  # Start the server with Rack 3.1 compatible handler
  options = {
    Port: 3000,
    Host: 'localhost',
    Logger: logger,
    AccessLog: []
  }

  logger.info("Echo Agent is running at http://localhost:9292")
  logger.info("Press Ctrl+C to stop")

  Rackup::Handler::WEBrick.run(app, **options)
end
