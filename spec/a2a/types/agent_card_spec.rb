# frozen_string_literal: true

RSpec.describe A2A::AgentCard do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      # Attributes defined in the factory are snake case
      let(:agent_card_attributes) { attributes_for(:agent_card) }

      it 'initializes an agent card' do
        agent_card = described_class.new(agent_card_attributes)

        expect(agent_card).to be_a(described_class)
      end
    end

    context 'when given attributes with camel case keys' do
      # Uses the snake key attributes from the factory and overrides some with camel case keys
      let(:agent_card_attributes) do
        attributes_for(:agent_card).merge(
          protocolVersion: '0.3.0',
          preferredTransport: 'JSONRPC',
          defaultInputModes: ['text/plain'],
          defaultOutputModes: ['application/json']
        )
      end

      it 'initializes an agent card' do
        agent_card = described_class.new(agent_card_attributes)

        expect(agent_card).to be_a(described_class)
      end
    end

    context 'when the optional attributes are missing' do
      let(:agent_card_attributes) do
        attributes_for(:agent_card).except(
          :additional_interfaces,
          :icon_url,
          :documentation_url,
          :security_schemes,
          :security,
          :supports_authenticated_extended_card,
          :signatures
        )
      end

      it 'initializes an agent card', :aggregate_failures do
        agent_card = described_class.new(agent_card_attributes)

        expect(agent_card).to be_a(described_class)
        expect(agent_card.additional_interfaces).to be_nil
        expect(agent_card.icon_url).to be_nil
        expect(agent_card.documentation_url).to be_nil
        expect(agent_card.security_schemes).to be_nil
        expect(agent_card.security).to be_nil
        expect(agent_card.supports_authenticated_extended_card).to be(false)
        expect(agent_card.signatures).to be_nil
      end
    end

    context 'when the required attributes are missing' do
      let(:agent_card_attributes) do
        attributes_for(:agent_card).except(
          :protocol_version,
          :name,
          :description,
          :url,
          :preferred_transport,
          :provider,
          :version,
          :capabilities,
          :default_input_modes,
          :default_output_modes,
          :skills
        )
      end

      it 'raises an error' do
        expect { described_class.new(agent_card_attributes) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    let(:agent_card) { build(:agent_card) }

    it 'converts the agent card to a hash' do
      expect(agent_card.to_h).to eq(
        protocol_version: '0.3.0',
        name: 'GeoSpatial Route Planner Agent',
        description: 'Provides advanced route planning, traffic analysis, and custom map generation ' \
                     'services. This agent can calculate optimal routes, estimate travel times considering ' \
                     'real-time traffic, and create personalized maps with points of interest.',
        url: URI('https://georoute-agent.example.com/a2a/v1'),
        preferred_transport: 'JSONRPC',
        additional_interfaces: [
          {
            url: URI('https://georoute-agent.example.com/a2a/v1'),
            transport: 'JSONRPC'
          },
          {
            url: URI('https://georoute-agent.example.com/a2a/grpc'),
            transport: 'GRPC'
          },
          {
            url: URI('https://georoute-agent.example.com/a2a/json'),
            transport: 'HTTP+JSON'
          }
        ],
        icon_url: URI('https://georoute-agent.example.com/icon.png'),
        provider: {
          organization: 'Google',
          url: URI('https://google.com')
        },
        version: '1.2.0',
        documentation_url: URI('https://docs.examplegeoservices.com/georoute-agent/api'),
        capabilities: {
          streaming: true,
          push_notifications: true,
          state_transition_history: true,
          extensions: nil
        },
        security_schemes: {
          'google' => {
            type: 'openIdConnect',
            open_id_connect_url: URI('https://accounts.google.com/.well-known/openid-configuration'),
            description: 'Google OpenID Connect authentication'
          }
        },
        security: [
          {
            'google' => %w[openid profile email]
          }
        ],
        default_input_modes: ['application/json', 'text/plain'],
        default_output_modes: ['application/json', 'image/png'],
        skills: [
          {
            id: 'route-planner',
            name: 'Route planning',
            description: 'Helps plan routing between two locations',
            tags: %w[maps routing navigation],
            examples: ['plan my route from Sunnyvale to Mountain View'],
            input_modes: ['text/plain'],
            output_modes: ['application/html', 'video/mp4'],
            security: nil
          },
          {
            id: 'custom-map',
            name: 'My Map',
            description: 'Manage a custom map with your own saved places',
            tags: %w[custom-map saved-places],
            examples: ['show me my favorite restaurants on the map'],
            input_modes: ['text/plain'],
            output_modes: ['application/html'],
            security: nil
          }
        ],
        supports_authenticated_extended_card: true,
        signatures: [
          {
            protected: 'eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMSIsImprdSI6Imh0dHBzOi8vZXhh' \
                       'bXBsZS5jb20vYWdlbnQvandrcy5qc29uIn0',
            signature: 'QFdkNLNszlGj3z3u0YQGt_T9LixY3qtdQpZmsTdDHDe3fXV9y9-B3m2-XgCpzuhiLt8E0tV6HXoZKHv4GtHgKQ',
            header: nil
          }
        ]
      )
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:agent_card) { build(:agent_card) }

      it 'returns a JSON string with camel case keys' do
        expect(agent_card.to_json).to match_json(<<~JSON)
          {
            "protocolVersion": "0.3.0",
            "name": "GeoSpatial Route Planner Agent",
            "description": "Provides advanced route planning, traffic analysis, and custom map generation services. This agent can calculate optimal routes, estimate travel times considering real-time traffic, and create personalized maps with points of interest.",
            "url": "https://georoute-agent.example.com/a2a/v1",
            "preferredTransport": "JSONRPC",
            "additionalInterfaces": [
              {
                "url": "https://georoute-agent.example.com/a2a/v1",
                "transport": "JSONRPC"
              },
              {
                "url": "https://georoute-agent.example.com/a2a/grpc",
                "transport": "GRPC"
              },
              {
                "url": "https://georoute-agent.example.com/a2a/json",
                "transport": "HTTP+JSON"
              }
            ],
            "iconUrl": "https://georoute-agent.example.com/icon.png",
            "provider": {
              "organization": "Google",
              "url": "https://google.com"
            },
            "version": "1.2.0",
            "documentationUrl": "https://docs.examplegeoservices.com/georoute-agent/api",
            "capabilities": {
              "streaming": true,
              "pushNotifications": true,
              "stateTransitionHistory": true,
              "extensions": null
            },
            "securitySchemes": {
              "google": {
                "type": "openIdConnect",
                "openIdConnectUrl": "https://accounts.google.com/.well-known/openid-configuration",
                "description": "Google OpenID Connect authentication"
              }
            },
            "security": [
              {
                "google": ["openid", "profile", "email"]
              }
            ],
            "defaultInputModes": ["application/json", "text/plain"],
            "defaultOutputModes": ["application/json", "image/png"],
            "skills": [
              {
                "id": "route-planner",
                "name": "Route planning",
                "description": "Helps plan routing between two locations",
                "tags": ["maps", "routing", "navigation"],
                "examples": ["plan my route from Sunnyvale to Mountain View"],
                "inputModes": ["text/plain"],
                "outputModes": ["application/html", "video/mp4"],
                "security": null
              },
              {
                "id": "custom-map",
                "name": "My Map",
                "description": "Manage a custom map with your own saved places",
                "tags": ["custom-map", "saved-places"],
                "examples": ["show me my favorite restaurants on the map"],
                "inputModes": ["text/plain"],
                "outputModes": ["application/html"],
                "security": null
              }
            ],
            "supportsAuthenticatedExtendedCard": true,
            "signatures": [
              {
                "protected": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMSIsImprdSI6Imh0dHBzOi8vZXhhbXBsZS5jb20vYWdlbnQvandrcy5qc29uIn0",
                "signature": "QFdkNLNszlGj3z3u0YQGt_T9LixY3qtdQpZmsTdDHDe3fXV9y9-B3m2-XgCpzuhiLt8E0tV6HXoZKHv4GtHgKQ",
                "header": null
              }
            ]
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:agent_card) { build(:agent_card) }

      it 'returns a JSON string with snake case keys' do
        expect(agent_card.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "protocol_version": "0.3.0",
            "name": "GeoSpatial Route Planner Agent",
            "description": "Provides advanced route planning, traffic analysis, and custom map generation services. This agent can calculate optimal routes, estimate travel times considering real-time traffic, and create personalized maps with points of interest.",
            "url": "https://georoute-agent.example.com/a2a/v1",
            "preferred_transport": "JSONRPC",
            "additional_interfaces": [
              {
                "url": "https://georoute-agent.example.com/a2a/v1",
                "transport": "JSONRPC"
              },
              {
                "url": "https://georoute-agent.example.com/a2a/grpc",
                "transport": "GRPC"
              },
              {
                "url": "https://georoute-agent.example.com/a2a/json",
                "transport": "HTTP+JSON"
              }
            ],
            "icon_url": "https://georoute-agent.example.com/icon.png",
            "provider": {
              "organization": "Google",
              "url": "https://google.com"
            },
            "version": "1.2.0",
            "documentation_url": "https://docs.examplegeoservices.com/georoute-agent/api",
            "capabilities": {
              "streaming": true,
              "push_notifications": true,
              "state_transition_history": true,
              "extensions": null
            },
            "security_schemes": {
              "google": {
                "type": "openIdConnect",
                "open_id_connect_url": "https://accounts.google.com/.well-known/openid-configuration",
                "description": "Google OpenID Connect authentication"
              }
            },
            "security": [
              {
                "google": ["openid", "profile", "email"]
              }
            ],
            "default_input_modes": ["application/json", "text/plain"],
            "default_output_modes": ["application/json", "image/png"],
            "skills": [
              {
                "id": "route-planner",
                "name": "Route planning",
                "description": "Helps plan routing between two locations",
                "tags": ["maps", "routing", "navigation"],
                "examples": ["plan my route from Sunnyvale to Mountain View"],
                "input_modes": ["text/plain"],
                "output_modes": ["application/html", "video/mp4"],
                "security": null
              },
              {
                "id": "custom-map",
                "name": "My Map",
                "description": "Manage a custom map with your own saved places",
                "tags": ["custom-map", "saved-places"],
                "examples": ["show me my favorite restaurants on the map"],
                "input_modes": ["text/plain"],
                "output_modes": ["application/html"],
                "security": null
              }
            ],
            "supports_authenticated_extended_card": true,
            "signatures": [
              {
                "protected": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMSIsImprdSI6Imh0dHBzOi8vZXhhbXBsZS5jb20vYWdlbnQvandrcy5qc29uIn0",
                "signature": "QFdkNLNszlGj3z3u0YQGt_T9LixY3qtdQpZmsTdDHDe3fXV9y9-B3m2-XgCpzuhiLt8E0tV6HXoZKHv4GtHgKQ",
                "header": null
              }
            ]
          }
        JSON
      end
    end
  end

  describe '.from_json' do
    let(:json_string) do
      <<~JSON
        {
          "protocolVersion": "0.3.0",
          "name": "GeoSpatial Route Planner Agent",
          "description": "Provides advanced route planning services",
          "url": "https://georoute-agent.example.com/a2a/v1",
          "preferredTransport": "JSONRPC",
          "additionalInterfaces": [
            {
              "url": "https://georoute-agent.example.com/a2a/v1",
              "transport": "JSONRPC"
            },
            {
              "url": "https://georoute-agent.example.com/a2a/grpc",
              "transport": "GRPC"
            }
          ],
          "iconUrl": "https://georoute-agent.example.com/icon.png",
          "provider": {
            "organization": "Example Geo Services Inc.",
            "url": "https://www.examplegeoservices.com"
          },
          "version": "1.2.0",
          "documentationUrl": "https://docs.examplegeoservices.com/georoute-agent/api",
          "capabilities": {
            "streaming": true,
            "pushNotifications": true,
            "stateTransitionHistory": false
          },
          "securitySchemes": {
            "google": {
              "type": "openIdConnect",
              "openIdConnectUrl": "https://accounts.google.com/.well-known/openid-configuration",
              "description": "Google OpenID Connect authentication"
            }
          },
          "security": [
            {
              "google": ["openid", "profile", "email"]
            }
          ],
          "defaultInputModes": ["application/json", "text/plain"],
          "defaultOutputModes": ["application/json", "image/png"],
          "skills": [
            {
              "id": "route-optimizer-traffic",
              "name": "Traffic-Aware Route Optimizer",
              "description": "Calculates optimal driving routes",
              "tags": ["maps", "routing", "navigation", "traffic"],
              "examples": ["Plan a route from San Francisco to Los Angeles"]
            }
          ],
          "supportsAuthenticatedExtendedCard": true,
          "signatures": [
            {
              "protected": "eyJhbGciOiJFUzI1NiJ9",
              "signature": "abc123"
            }
          ]
        }
      JSON
    end

    it 'initializes an agent card' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card).to be_a(described_class)
    end

    it 'parses protocol_version' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.protocol_version).to eq('0.3.0')
    end

    it 'parses name' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.name).to eq('GeoSpatial Route Planner Agent')
    end

    it 'parses description' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.description).to eq('Provides advanced route planning services')
    end

    it 'parses url' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.url).to eq(URI('https://georoute-agent.example.com/a2a/v1'))
    end

    it 'parses preferred_transport' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.preferred_transport).to eq('JSONRPC')
    end

    it 'parses version' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.version).to eq('1.2.0')
    end

    it 'parses icon_url' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.icon_url).to eq(URI('https://georoute-agent.example.com/icon.png'))
    end

    it 'parses documentation_url' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.documentation_url).to eq(URI('https://docs.examplegeoservices.com/georoute-agent/api'))
    end

    it 'parses supports_authenticated_extended_card' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.supports_authenticated_extended_card).to be(true)
    end

    it 'parses additional_interfaces' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.additional_interfaces).to eq(
        [
          A2A::AgentInterface.new(
            url: 'https://georoute-agent.example.com/a2a/v1',
            transport: 'JSONRPC'
          ),
          A2A::AgentInterface.new(
            url: 'https://georoute-agent.example.com/a2a/grpc',
            transport: 'GRPC'
          )
        ]
      )
    end

    it 'parses provider' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.provider).to eq(
        A2A::AgentProvider.new(
          organization: 'Example Geo Services Inc.',
          url: 'https://www.examplegeoservices.com'
        )
      )
    end

    it 'parses capabilities' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.capabilities).to eq(
        A2A::AgentCapabilities.new(
          streaming: true,
          push_notifications: true,
          state_transition_history: false
        )
      )
    end

    it 'parses security_schemes' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.security_schemes).to eq(
        google: A2A::OpenIdConnectSecurityScheme.new(
          type: 'openIdConnect',
          open_id_connect_url: 'https://accounts.google.com/.well-known/openid-configuration',
          description: 'Google OpenID Connect authentication'
        )
      )
    end

    it 'parses security' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.security).to eq(
        [
          { google: %w[openid profile email] }
        ]
      )
    end

    it 'parses default_input_modes' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.default_input_modes).to eq(['application/json', 'text/plain'])
    end

    it 'parses default_output_modes' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.default_output_modes).to eq(['application/json', 'image/png'])
    end

    it 'parses skills' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.skills).to eq(
        [
          A2A::AgentSkill.new(
            id: 'route-optimizer-traffic',
            name: 'Traffic-Aware Route Optimizer',
            description: 'Calculates optimal driving routes',
            tags: %w[maps routing navigation traffic],
            examples: ['Plan a route from San Francisco to Los Angeles']
          )
        ]
      )
    end

    it 'parses signatures' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card.signatures).to eq(
        [
          A2A::AgentCardSignature.new(
            protected: 'eyJhbGciOiJFUzI1NiJ9',
            signature: 'abc123'
          )
        ]
      )
    end
  end
end
