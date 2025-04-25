# frozen_string_literal: true

require 'a2a'

agent = A2A::Agent.define do
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

  # on_task TaskManager
  # on_task_subscribe AsyncTaskManager

  # Hook for logging
  before_task do |task|
    puts "Task received: #{task.id}"
  end

  # on_task_transition do |task, task_state|
  #
  # end

  after_task do |task|
    puts "Task completed: #{task.id}"
  end

  on_task do |task|
    # Handle incoming tasks
    text = task.message.parts.first.text
    task.complete("You said: #{text}")
  end

  on_task_subscribe do |task, stream|
    # Handle streaming task
    text = task.message.parts.first.text
    stream.send_update("Processing: #{text}", state: "working")
    sleep 1
    stream.send_update("Finished processing!", state: "completed", final: true)
  end
end
