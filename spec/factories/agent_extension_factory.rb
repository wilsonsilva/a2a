# frozen_string_literal: true

FactoryBot.define do
  factory :agent_extension, class: 'A2A::AgentExtension' do
    initialize_with { new(**attributes) }

    trait :optional_extension do
      uri { URI('https://a2a.dev/extensions/custom-maps-v1') }
      description { 'Custom map styling and overlay capabilities' }
      required { false }
      params { { 'maxLayers' => 10, 'supportedFormats' => %w[geojson kml] } }
    end

    trait :required_extension do
      uri { URI('https://a2a.dev/extensions/auth-v1') }
      description { 'Enhanced authentication for secure map data' }
      required { true }
      params { { 'authType' => 'oauth2' } }
    end

    optional_extension
  end
end
