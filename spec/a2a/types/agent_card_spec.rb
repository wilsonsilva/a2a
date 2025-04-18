# frozen_string_literal: true

RSpec.describe A2A::AgentCard do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      let(:agent_card_attributes) do
        attributes_for(:agent_card).merge(
          capabilities: attributes_for(:agent_capabilities),
          authentication: attributes_for(:agent_authentication),
          skills: [attributes_for(:agent_skill)],
          provider: attributes_for(:agent_provider)
        )
      end

      it 'initializes an agent card' do
        agent_card = described_class.new(agent_card_attributes)

        expect(agent_card).to be_a(described_class)
      end
    end

    context 'when given attributes with camel case keys' do
      let(:agent_card_attributes) do
        attributes_for(:agent_card).merge(
          defaultInputModes: ['text/plain'],
          defaultOutputModes: %w[text/plain application/html],
          capabilities: attributes_for(:agent_capabilities),
          authentication: attributes_for(:agent_authentication),
          skills: [attributes_for(:agent_skill)],
          provider: attributes_for(:agent_provider)
        )
      end

      it 'initializes an agent card' do
        agent_card = described_class.new(agent_card_attributes)

        expect(agent_card).to be_a(described_class)
      end
    end

    context 'when given object instances' do
      let(:agent_card_attributes) do
        attributes_for(:agent_card).merge(
          capabilities: build(:agent_capabilities),
          authentication: build(:agent_authentication),
          skills: [build(:agent_skill)],
          provider: build(:agent_provider)
        )
      end

      it 'initializes an agent card' do
        agent_card = described_class.new(agent_card_attributes)

        expect(agent_card).to be_a(described_class)
      end
    end

    context 'when the default attributes are missing' do
      let(:agent_card_attributes) do
        attributes_for(:agent_card).merge(
          capabilities: attributes_for(:agent_capabilities),
          authentication: attributes_for(:agent_authentication),
          skills: [attributes_for(:agent_skill)],
          provider: attributes_for(:agent_provider)
        ).except(:default_input_modes, :default_output_modes)
      end

      it 'initializes an agent card with default attributes', :aggregate_failures do
        agent_card = described_class.new(agent_card_attributes)

        expect(agent_card).to be_a(described_class)
        expect(agent_card.default_input_modes).to eq(['text'])
        expect(agent_card.default_output_modes).to eq(['text'])
      end
    end

    context 'when the default attributes overridden' do
      let(:agent_card_attributes) do
        attributes_for(:agent_card).merge(
          default_input_modes: ['application/pdf'],
          default_output_modes: %w[application/octet-stream text/csv],
          capabilities: attributes_for(:agent_capabilities),
          authentication: attributes_for(:agent_authentication),
          skills: [attributes_for(:agent_skill)],
          provider: attributes_for(:agent_provider)
        )
      end

      it 'initializes an agent card with overridden attributes', :aggregate_failures do
        agent_card = described_class.new(agent_card_attributes)

        expect(agent_card).to be_a(described_class)
        expect(agent_card.default_input_modes).to eq(['application/pdf'])
        expect(agent_card.default_output_modes).to eq(%w[application/octet-stream text/csv])
      end
    end

    context 'when the required attributes are missing' do
      let(:agent_card_attributes) do
        attributes_for(:agent_card).merge(
          authentication: attributes_for(:agent_authentication)
        ).except(:name, :url, :version, :capabilities, :skills)
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
        name: 'Google Maps Agent',
        description: 'Plan routes, remember places, and generate directions',
        url: 'https://maps-agent.google.com',
        provider: {
          organization: 'Google',
          url: 'https://google.com'
        },
        version: '1.0.0',
        documentation_url: 'https://example.com/docs',
        capabilities: {
          streaming: false,
          push_notifications: false,
          state_transition_history: false
        },
        authentication: {
          schemes: ['OAuth2']
        },
        default_input_modes: ['text/plain'],
        default_output_modes: %w[text/plain application/html],
        skills: [
          {
            id: 'route-planner',
            name: 'Route planning',
            description: 'Helps plan routing between two locations',
            tags: %w[maps routing navigation],
            examples: ['plan my route from Sunnyvale to Mountain View'],
            input_modes: ['text/plain'],
            output_modes: %w[application/html video/mp4]
          },
          {
            id: 'custom-map',
            name: 'My Map',
            description: 'Manage a custom map with your own saved places',
            tags: %w[custom-map saved-places],
            examples: ['show me my favorite restaurants on the map'],
            input_modes: ['text/plain'],
            output_modes: ['application/html']
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
            "name": "Google Maps Agent",
            "description": "Plan routes, remember places, and generate directions",
            "url": "https://maps-agent.google.com",
            "provider": {
              "organization": "Google",
              "url": "https://google.com"
            },
            "version": "1.0.0",
            "documentationUrl": "https://example.com/docs",
            "capabilities": {
              "streaming": false,
              "pushNotifications": false,
              "stateTransitionHistory": false
            },
            "authentication": {
              "schemes": ["OAuth2"]
            },
            "defaultInputModes": ["text/plain"],
            "defaultOutputModes": ["text/plain", "application/html"],
            "skills": [
              {
                "id": "route-planner",
                "name": "Route planning",
                "description": "Helps plan routing between two locations",
                "tags": ["maps", "routing", "navigation"],
                "examples": ["plan my route from Sunnyvale to Mountain View"],
                "inputModes": ["text/plain"],
                "outputModes": ["application/html", "video/mp4"]
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
            "name": "Google Maps Agent",
            "description": "Plan routes, remember places, and generate directions",
            "url": "https://maps-agent.google.com",
            "provider": {
              "organization": "Google",
              "url": "https://google.com"
            },
            "version": "1.0.0",
            "documentation_url": "https://example.com/docs",
            "capabilities": {
              "streaming": false,
              "push_notifications": false,
              "state_transition_history": false
            },
            "authentication": {
              "schemes": ["OAuth2"]
            },
            "default_input_modes": ["text/plain"],
            "default_output_modes": ["text/plain", "application/html"],
            "skills": [
              {
                "id": "route-planner",
                "name": "Route planning",
                "description": "Helps plan routing between two locations",
                "tags": ["maps", "routing", "navigation"],
                "examples": ["plan my route from Sunnyvale to Mountain View"],
                "input_modes": ["text/plain"],
                "output_modes": ["application/html", "video/mp4"]
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
          "name": "Google Maps Agent",
          "description": "Plan routes, remember places, and generate directions",
          "url": "https://maps-agent.google.com",
          "provider": {
            "organization": "Google",
            "url": "https://google.com"
          },
          "version": "1.0.0",
          "documentationUrl": "https://example.com/docs",
          "capabilities": {
            "streaming": false,
            "pushNotifications": false,
            "stateTransitionHistory": false
          },
          "authentication": {
            "schemes": ["OAuth2"]
          },
          "defaultInputModes": ["text/plain"],
          "defaultOutputModes": ["text/plain", "application/html"],
          "skills": [
            {
              "id": "route-planner",
              "name": "Route planning",
              "description": "Helps plan routing between two locations",
              "tags": ["maps", "routing", "navigation"],
              "examples": ["plan my route from Sunnyvale to Mountain View"],
              "inputModes": ["text/plain"],
              "outputModes": ["application/html", "video/mp4"]
            }
          ]
        }
      JSON
    end

    it 'initializes an agent card' do
      agent_card = described_class.from_json(json_string)

      expect(agent_card).to be_a(described_class)
    end
  end
end
