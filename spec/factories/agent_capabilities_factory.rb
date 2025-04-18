# frozen_string_literal: true

FactoryBot.define do
  factory :agent_capabilities, class: 'A2A::AgentCapabilities' do
    initialize_with { new(**attributes) }

    trait :incapable do
      streaming { false }
      push_notifications { false }
      state_transition_history { false }
    end

    trait :fully_capable do
      streaming { true }
      push_notifications { true }
      state_transition_history { true }
    end

    incapable
  end
end
