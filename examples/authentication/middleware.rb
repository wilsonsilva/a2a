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

  # Use middleware for authentication
  use A2A::Middleware::Authentication do |request, env|
    # Verify bearer token
    token = env['HTTP_AUTHORIZATION']&.gsub('Bearer ', '')

    # Use your authentication logic here
    if token == 'valid-token'
      true
    else
      raise A2A::Errors::InvalidRequest.new("Invalid authentication")
    end
  end
end
