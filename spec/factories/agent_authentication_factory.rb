# frozen_string_literal: true

FactoryBot.define do
  factory :agent_authentication, class: 'A2A::AgentAuthentication' do
    initialize_with { new(**attributes) }

    trait :api_key do
      schemes { ['apiKey'] }
    end

    trait :http do
      schemes { ['http'] }
    end

    trait :oauth2 do
      schemes { ['OAuth2'] }
    end

    trait :open_id_connect do
      schemes { ['openIdConnect'] }
    end

    trait :all do
      schemes { %w[apiKey http OAuth2 openIdConnect] }
    end

    oauth2
  end
end
