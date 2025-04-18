# frozen_string_literal: true

FactoryBot.define do
  factory :agent_skill, class: 'A2A::AgentSkill' do
    initialize_with { new(**attributes) }

    trait :route_planner do
      id { 'route-planner' }
      name { 'Route planning' }
      description { 'Helps plan routing between two locations' }
      tags { %w[maps routing navigation] }
      examples { ['plan my route from Sunnyvale to Mountain View'] }
      input_modes { ['text/plain'] }
      output_modes { %w[application/html video/mp4] }
    end

    trait :custom_map do
      id { 'custom-map' }
      name { 'My Map' }
      description { 'Manage a custom map with your own saved places' }
      tags { %w[custom-map saved-places] }
      examples { ['show me my favorite restaurants on the map'] }
      input_modes { ['text/plain'] }
      output_modes { ['application/html'] }
    end

    route_planner
  end
end
