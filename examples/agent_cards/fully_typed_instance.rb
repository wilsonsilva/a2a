# frozen_string_literal: true

require 'a2a'

agent = A2A::Agent.build do
  card A2A::AgentCard.new(
    name: 'Google Maps Agent',
    description: 'Plan routes, remember places, and generate directions',
    url: 'https://maps-agent.google.com',
    provider: A2A::AgentProvider.new(
      organization: 'Google',
      url: 'https://google.com'
    ),
    version: '1.0.0',
    documentation_url: 'https://example.com/docs',
    capabilities: A2A::AgentCapabilities.new(
      streaming: false,
      push_notifications: false,
      state_transition_history: false
    ),
    authentication: A2A::AgentAuthentication.new(
      schemes: ['OAuth2']
    ),
    default_input_modes: ['text/plain'],
    default_output_modes: ['text/plain', 'application/html'],
    skills: [
      A2A::AgentSkill.new(
        id: 'route-planner',
        name: 'Route planning',
        description: 'Helps plan routing between two locations',
        tags: %w[maps routing navigation],
        examples: ['plan my route from Sunnyvale to Mountain View'],
        input_modes: ['text/plain'],
        output_modes: ['application/html', 'video/mp4']
      ),
      A2A::AgentSkill.new(
        id: 'place-reminder',
        name: 'Place Reminder',
        description: 'Reminds you of places you want to remember',
        tags: %w[maps reminder location],
        examples: ['remind me of the coffee shop in Mountain View'],
        input_modes: ['text/plain'],
        output_modes: ['text/plain']
      )
    ]
  )
end
