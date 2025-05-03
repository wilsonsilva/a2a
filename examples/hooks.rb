# frozen_string_literal: true

# a2a/examples/hooks.rb

require '../lib/a2a'

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

  before_task do |task|
  end

  on_task_transition do |task, previous_state, current_state|
  end

  after_task do |task|
  end

  on_task do |task|
  end

  on_task_subscribe do |task, stream|
  end
end

