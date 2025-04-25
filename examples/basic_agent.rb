#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'a2a'

# Configure A2A
A2A.configure do |config|
  config[:log_level] = :debug
end

# Define a simple agent
agent = A2A::Agent.build do
  card do
    name 'Google Maps Agent'
    url 'https://maps-agent.google.com'
    version '1.0.0'

    capabilities do
      streaming false
      push_notifications false
      state_transition_history false
    end

    skill 'route-planner' do
      name 'Route planning'
      description 'Helps plan routing between two locations'
      tags %w[maps routing navigation]
      examples ['plan my route from Sunnyvale to Mountain View']
      input_modes ['text/plain']
      output_modes %w[application/html video/mp4]
    end
  end
end

# Create a task manager
task_manager = A2A::TaskManager.new

# Create a task processor
processor = A2A::TaskProcessor.new(agent, task_manager)

# Register handlers for different message types
processor.register_handler("route-planner") do |params, task|
  message = params[:message] || "No message provided"
  A2A::TaskProcessor.text_artifact("Echo: #{message}")
end

processor.register_handler("reverse") do |params, task|
  text = params[:text] || ""
  reversed = text.reverse
  A2A::TaskProcessor.text_artifact("Reversed: #{reversed}")
end

# Create and run the server
puts "Starting A2A example agent..."
A2A.run(agent, port: 3000)
