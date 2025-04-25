# frozen_string_literal: true

require 'a2a'

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

    skill 'Route planning' do
      id 'route-planner'
      description 'Helps plan routing between two locations'
      tags %w[maps routing navigation]
      examples ['plan my route from Sunnyvale to Mountain View']
      input_modes ['text/plain']
      output_modes %w[application/html video/mp4]
    end
  end

  task_manager TaskManager
  storage Storage

  before_task do |task|
    puts "Task received: #{task.id}"
  end

  on_task_transition do |task, previous_state, current_state|
    puts "Task #{task.id} transitioned from #{previous_state} to #{current_state}"
  end

  after_task do |task|
    puts "Task completed: #{task.id}"
  end

  on_task do |task|
    # Handle incoming tasks
    text = task.message.parts.first.text
    puts "You said: #{text}"
    # task.complete("You said: #{text}")
  end

  # on_task_subscribe do |task, stream|
  #   # Handle streaming task
  #   text = task.message.parts.first.text
  #   stream.send_update("Processing: #{text}", state: "working")
  #   sleep 1
  #   stream.send_update("Finished processing!", state: "completed", final: true)
  # end

  authenticate do |request|
    # Validate auth token and return true/false
    token = request.env['HTTP_AUTHORIZATION']&.slice(7..-1) # Remove 'Bearer '
    MyAuthService.validate_token(token)
  end

  # Use Redis for task storage
  task_store A2A::TaskStore::Redis.new(url: 'redis://localhost:6379/0')

  # Or custom store
  task_store MyCustomTaskStore.new

  on_error do |error, context|
    # Log error and possibly notify monitoring systems
    Sentry.capture_exception(error, extra: { task_id: context[:task_id] })
  end
end

# Create a Rack application
app = A2A::Transport.new(agent)

# Run with Rack
use Rack::Logger
run app
