#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'a2a'

# Create a new A2A server
server = A2A::Server.new(
  name: 'example-agent',
  version: '1.0.0',
  capabilities: {
    streaming: true,
    pushNotifications: false,
    stateTransitionHistory: true
  }
)

# Configure the server
server.set_agent_card(
  description: 'An example A2A agent',
  url: 'http://localhost:41241',
  provider: {
    organization: 'Example Organization',
    url: 'https://example.org'
  },
  defaultInputModes: ['text'],
  defaultOutputModes: ['text']
)

# Define a skill
greeting_skill = A2A::AgentSkill.new(
  id: 'greeting',
  name: 'Greeting',
  description: 'Processes greeting requests and responds appropriately',
  tags: ['greeting', 'hello', 'conversation'],
  examples: [
        'Say hello to me',
        'Good morning',
        'How are you doing?'
      ]
)

# Define a calculator skill
calculator_skill = A2A::AgentSkill.new(
  id: 'calculator',
  name: 'Calculator',
  description: 'Performs basic arithmetic operations',
  tags: ['math', 'calculation', 'arithmetic'],
  examples: [
        'What is 2 + 2?',
        'Calculate 15 * 7',
        'Divide 100 by 5'
      ]
)

# Register the skills
server.register_skills(greeting_skill, calculator_skill)

# Register the task handler
server.register_task_handler do |task, message|
  puts "Processing task #{task.id} with message: #{message.inspect}"

  # Check if this is a new task or a continuation
  if task.status.state == 'submitted'
    # New task, let's acknowledge receipt
    task.status.state = 'working'
    task.status.timestamp = Time.now.iso8601
    task.status.message = A2A::Message.new(
      role: 'agent',
      parts: [
              A2A::TextPart.new(
                type: 'text',
                text: 'Thinking about your request...'
              )
            ]
    )
    return task
  end

  # Extract message text for processing
  text = message['parts'].first['text']

  # Process based on the content
  if text.downcase.match?(/hello|hi|hey|greetings/i)
    # This is a greeting
    task.status.state = 'completed'
    task.status.timestamp = Time.now.iso8601
    task.status.message = A2A::Message.new(
      role: 'agent',
      parts: [
              A2A::TextPart.new(
                type: 'text',
                text: "Hello there! How can I help you today?"
              )
            ]
    )
  elsif text.match?(/(\d+)\s*[\+\-\*\/]\s*(\d+)/)
    # This appears to be a calculation
    operation = text.match(/(\d+)\s*([\+\-\*\/])\s*(\d+)/)
    result = nil

    if operation
      num1 = operation[1].to_i
      operator = operation[2]
      num2 = operation[3].to_i

      result = case operator
               when '+' then num1 + num2
               when '-' then num1 - num2
               when '*' then num1 * num2
               when '/' then num1.to_f / num2
               end
    end

    if result
      task.status.state = 'completed'
      task.status.timestamp = Time.now.iso8601
      task.status.message = A2A::Message.new(
        role: 'agent',
        parts: [
                A2A::TextPart.new(
                  type: 'text',
                  text: "The result of #{num1} #{operator} #{num2} is #{result}"
                )
              ]
      )

      # Add an artifact with the calculation details
      task.artifacts ||= []
      task.artifacts << A2A::Artifact.new(
        name: 'calculation_result',
        description: 'Detailed calculation result',
        parts: [
                A2A::DataPart.new(
                  type: 'data',
                  data: {
                    operation: "#{num1} #{operator} #{num2}",
                    operand1: num1,
                    operand2: num2,
                    operator: operator,
                    result: result
                  }
                )
              ]
      )
    else
      task.status.state = 'input-required'
      task.status.timestamp = Time.now.iso8601
      task.status.message = A2A::Message.new(
        role: 'agent',
        parts: [
                A2A::TextPart.new(
                  type: 'text',
                  text: "I couldn't parse that calculation. Please provide an expression like '2 + 2'."
                )
              ]
      )
    end
  else
    # We didn't understand the request
    task.status.state = 'input-required'
    task.status.timestamp = Time.now.iso8601
    task.status.message = A2A::Message.new(
      role: 'agent',
      parts: [
              A2A::TextPart.new(
                type: 'text',
                text: "I'm not sure what you're asking for. I can respond to greetings or perform simple calculations."
              )
            ]
    )
  end

  task
end

puts "Starting A2A server with STDIO transport..."
puts "Available skills: #{server.card.skills.map(&:id).join(', ')}"
puts "Send JSON-RPC requests to interact with the server."
puts "Example: {\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tasks/send\",\"params\":{\"id\":\"task-123\",\"message\":{\"role\":\"user\",\"parts\":[{\"type\":\"text\",\"text\":\"Hello\"}]}}}"

# Start the server
server.start
