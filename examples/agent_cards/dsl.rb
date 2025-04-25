# frozen_string_literal: true

require 'a2a'

agent = A2A::Agent.build do
  card do
    name 'Google Maps Agent'
    description 'Plan routes, remember places, and generate directions'
    url 'https://maps-agent.google.com'

    provider do
      organization 'Google'
      url 'https://google.com'
    end

    version '1.0.0'
    documentation_url 'https://example.com/docs'

    capabilities do
      streaming false
      push_notifications false
      state_transition_history false
    end

    authentication do
      schemes ['OAuth2']
    end

    default_input_modes ['text/plain']
    default_output_modes %w[text/plain application/html]

    skill 'Route planning' do
      id 'route-planner'
      description 'Helps plan routing between two locations'
      tags %w[maps routing navigation]
      examples ['plan my route from Sunnyvale to Mountain View']
      input_modes ['text/plain']
      output_modes %w[application/html video/mp4]
    end

    skill 'Place Reminder' do
      id 'place-reminder'
      description 'Reminds you of places you want to remember'
      tags %w[maps reminder location]
      examples ['remind me of the coffee shop in Mountain View']
      input_modes ['text/plain']
      output_modes ['text/plain']
    end
  end
end
