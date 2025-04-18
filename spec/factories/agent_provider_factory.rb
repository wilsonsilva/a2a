# frozen_string_literal: true

FactoryBot.define do
  factory :agent_provider, class: 'A2A::AgentProvider' do
    initialize_with { new(**attributes) }

    trait :google do
      organization { 'Google' }
      url { 'https://google.com' }
    end

    google
  end
end
