# frozen_string_literal: true

FactoryBot.define do
  factory :agent_card, class: 'A2A::AgentCard' do
    initialize_with { new(**attributes) }

    trait :google_maps do
      protocol_version { '0.3.0' }
      name { 'GeoSpatial Route Planner Agent' }
      description do
        'Provides advanced route planning, traffic analysis, and custom map generation services. ' \
          'This agent can calculate optimal routes, estimate travel times considering real-time traffic, ' \
          'and create personalized maps with points of interest.'
      end
      url { 'https://georoute-agent.example.com/a2a/v1' }
      preferred_transport { 'JSONRPC' }
      additional_interfaces do
        [
          build(:agent_interface, :jsonrpc),
          build(:agent_interface, :grpc),
          build(:agent_interface, :http_json)
        ]
      end
      icon_url { 'https://georoute-agent.example.com/icon.png' }
      provider factory: :agent_provider, traits: [:google]
      version { '1.2.0' }
      documentation_url { 'https://docs.examplegeoservices.com/georoute-agent/api' }
      capabilities { build(:agent_capabilities, :fully_capable) } # rubocop:disable FactoryBot/FactoryAssociationWithStrategy
      security_schemes do
        {
          'google' => build(:openid_connect_security_scheme, :google_oidc)
        }
      end
      security do
        [
          { 'google' => %w[openid profile email] }
        ]
      end
      default_input_modes { %w[application/json text/plain] }
      default_output_modes { %w[application/json image/png] }
      skills do
        [
          build(:agent_skill, :route_planner),
          build(:agent_skill, :custom_map)
        ]
      end
      supports_authenticated_extended_card { true }
      signatures do
        [
          build(:agent_card_signature, :example_signature)
        ]
      end
    end

    google_maps
  end
end
