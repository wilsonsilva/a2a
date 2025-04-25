# frozen_string_literal: true

require 'a2a'

agent = A2A::Agent.build do
  card 'well-known/agent.json'

  # Using task managers
  # on_task TaskManager
  # on_task_subscribe AsyncTaskManager

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
end
