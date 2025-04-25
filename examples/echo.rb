# frozen_string_literal: true

require 'a2a'
require 'rack'
require 'rackup'

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
    puts "Received task: #{task.id}"
  end

  # Log state transitions
  on_task_transition do |task, from, to|
    puts "Task #{task.id} state changed: #{from || 'new'} -> #{to}"
  end

  # Log when tasks are completed
  after_task do |task|
    puts "Task completed: #{task.id}"
  end

  # This is where the actual work happens
  on_task do |task|
    # Extract text from the first part of the message
    if task.message && task.message.parts && !task.message.parts.empty?
      part = task.message.parts.first

      if part.type == 'text'
        input_text = part.text
        echo_text = "Echo: #{input_text}"

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

        # Update task with response
        task.with_artifacts([artifact])
          .with_status(A2A::TaskStatus.new(
            state: 'completed',
            message: message,
            timestamp: Time.now.iso8601
          ))
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

        task.with_status(A2A::TaskStatus.new(
          state: 'failed',
          message: message,
          timestamp: Time.now.iso8601
        ))
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

      task.with_status(A2A::TaskStatus.new(
        state: 'failed',
        message: message,
        timestamp: Time.now.iso8601
      ))
    end
  end
end

# Create a Rack application
app = A2A::Transport.new(echo_agent)

# Run with Rackup when this file is executed directly
if __FILE__ == $0
  # A simple Rack handler to run the app
  Rackup::Handler::WEBrick.run(app, Port: 9292) do |server|
    puts "Echo Agent is running at http://localhost:9292"
    puts "Press Ctrl+C to stop"
  end
end
