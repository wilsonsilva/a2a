# frozen_string_literal: true

FactoryBot.define do
  factory :agent_interface, class: 'A2A::AgentInterface' do
    initialize_with { new(**attributes) }

    trait :jsonrpc do
      url { 'https://georoute-agent.example.com/a2a/v1' }
      transport { 'JSONRPC' }
    end

    trait :grpc do
      url { 'https://georoute-agent.example.com/a2a/grpc' }
      transport { 'GRPC' }
    end

    trait :http_json do
      url { 'https://georoute-agent.example.com/a2a/json' }
      transport { 'HTTP+JSON' }
    end

    jsonrpc
  end
end
