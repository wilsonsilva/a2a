# frozen_string_literal: true

FactoryBot.define do
  factory :agent_card, class: 'A2A::AgentCard' do
    initialize_with { new(**attributes) }

    trait :google_maps do
      name { 'Google Maps Agent' }
      description { 'Plan routes, remember places, and generate directions' }
      url { 'https://maps-agent.google.com' }
      provider factory: :agent_provider, traits: [:google]
      version { '1.0.0' }
      documentation_url { 'https://example.com/docs' }
      capabilities factory: :agent_capabilities, traits: [:incapable]
      authentication factory: :agent_authentication, traits: [:oauth2]
      default_input_modes { ['text/plain'] }
      default_output_modes { %w[text/plain application/html] }
      skills do
        [
          build(:agent_skill, :route_planner),
          build(:agent_skill, :custom_map)
        ]
      end
    end

    google_maps
  end
end
