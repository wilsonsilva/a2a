#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'rack'
require 'a2a'

# Define a simple Rack application
class SimpleApp
  def call(env)
    [200, { 'Content-Type' => 'text/html' }, ["<html><body><h1>Simple App</h1><p>A2A server is running at /a2a</p></body></html>"]]
  end
end

# Create a task handler class (optional, but helps organization)
class MyTaskHandler < A2A::TaskHandler
  def call(task, message)
    # Extract message text for processing
    text = message['parts'].first['text']

    # Check if the task is being cancelled
    if cancelled?(task)
      return failed_task(task, "Task was cancelled")
    end

    # Process based on the content
    if text.downcase.match?(/hello|hi|hey|greetings/i)
      # This is a greeting, return a completed task
      completed_task(task, "Hello there! How can I help you today?")
    elsif text.match?(/(\d+)\s*[\+\-\*\/]\s*(\d+)/)
      # This appears to be a calculation
      handle_calculation(task, text)
    else
      # We didn't understand the request
      input_required_task(
        task,
        "I'm not sure what you're asking for. I can respond to greetings or perform simple calculations."
      )
    end
  end

  private

  def handle_calculation(task, text)
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
      task = completed_task(task, "The result of #{num1} #{operator} #{num2} is #{result}")

      # Add an artifact with the calculation details
      artifact = A2A::Artifact.new(
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

      # Use helper method to add the artifact to the task
      add_artifact(task, artifact)
    else
      input_required_task(
        task,
        "I couldn't parse that calculation. Please provide an expression like '2 + 2'."
      )
    end
  end
end

# Create the rack application with A2A middleware
app = Rack::Builder.new do
  # Configure the A2A middleware
  use A2A.rack_middleware,
      name: 'rack-calculator',
      version: '1.0.0',
      path_prefix: '/a2a',
      allowed_origins: ['localhost', '127.0.0.1'] do |server|

    # Configure the server
    server.set_agent_card(
      description: 'A Rack-based A2A calculator agent',
      url: 'http://localhost:9292/a2a',
      provider: {
        organization: 'Example Organization',
        url: 'https://example.org'
      },
      defaultInputModes: ['text'],
      defaultOutputModes: ['text']
    )

    # Register skills
    server.register_skills(
      A2A::AgentSkill.new(
        id: 'greeting',
        name: 'Greeting',
        description: 'Processes greeting requests and responds appropriately',
        tags: ['greeting', 'hello', 'conversation'],
        examples: [
              'Say hello to me',
              'Good morning',
              'How are you doing?'
            ]
      ),
      A2A::AgentSkill.new(
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
    )

    # Register the task handler (using our class)
    task_handler = MyTaskHandler.new(server)
    server.register_task_handler do |task, message|
      task_handler.call(task, message)
    end
  end

  # Use the simple app as the base application
  run SimpleApp.new
end

# If this file is run directly, start the server
if __FILE__ == $0
  puts "Starting Rack server on port 9292..."
  puts "A2A server is accessible at http://localhost:9292/a2a"
  Rack::Handler::WEBrick.run app, Port: 9292
end
