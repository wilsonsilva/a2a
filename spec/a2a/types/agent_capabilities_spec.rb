# frozen_string_literal: true

RSpec.describe A2A::AgentCapabilities do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      # Attributes defined in the factory are snake case
      let(:agent_capabilities_attributes) { attributes_for(:agent_capabilities) }

      it 'initializes agent capabilities' do
        agent_capabilities = described_class.new(agent_capabilities_attributes)

        expect(agent_capabilities).to be_a(described_class)
      end
    end

    context 'when given attributes with camel case keys' do
      # Uses the snake key attributes from the factory and overrides some with camel case keys
      let(:agent_capabilities_attributes) do
        attributes_for(:agent_capabilities).merge(
          pushNotifications: false,
          stateTransitionHistory: false
        )
      end

      it 'initializes agent capabilities' do
        agent_capabilities = described_class.new(agent_capabilities_attributes)

        expect(agent_capabilities).to be_a(described_class)
      end
    end

    context 'when the default attributes are missing' do
      let(:agent_capabilities_attributes) do
        attributes_for(:agent_capabilities).except(:push_notifications, :state_transition_history, :streaming)
      end

      it 'initializes agent capabilities with default attributes', :aggregate_failures do
        agent_capabilities = described_class.new(agent_capabilities_attributes)

        expect(agent_capabilities).to be_a(described_class)
        expect(agent_capabilities.streaming).to be(false)
        expect(agent_capabilities.push_notifications).to be(false)
        expect(agent_capabilities.state_transition_history).to be(false)
      end
    end

    context 'when the default attributes are overridden' do
      let(:agent_capabilities_attributes) do
        {
          streaming: true,
          push_notifications: true,
          state_transition_history: true
        }
      end

      it 'initializes agent capabilities with overridden attributes', :aggregate_failures do
        agent_capabilities = described_class.new(agent_capabilities_attributes)

        expect(agent_capabilities).to be_a(described_class)
        expect(agent_capabilities.streaming).to be(true)
        expect(agent_capabilities.push_notifications).to be(true)
        expect(agent_capabilities.state_transition_history).to be(true)
      end
    end
  end

  describe '#to_h' do
    context 'without extensions' do
      let(:agent_capabilities) { build(:agent_capabilities, :incapable) }

      it 'converts the agent capabilities to a hash' do
        expect(agent_capabilities.to_h).to eq(
          streaming: false,
          push_notifications: false,
          state_transition_history: false,
          extensions: nil
        )
      end
    end

    context 'with extensions' do
      let(:agent_capabilities) { build(:agent_capabilities, :with_extensions) }

      it 'converts the agent capabilities to a hash with extensions' do
        expect(agent_capabilities.to_h).to eq(
          streaming: true,
          push_notifications: true,
          state_transition_history: false,
          extensions: [
            {
              uri: URI('https://a2a.dev/extensions/custom-maps-v1'),
              description: 'Custom map styling and overlay capabilities',
              required: false,
              params: { 'maxLayers' => 10, 'supportedFormats' => %w[geojson kml] }
            },
            {
              uri: URI('https://a2a.dev/extensions/auth-v1'),
              description: 'Enhanced authentication for secure map data',
              required: true,
              params: { 'authType' => 'oauth2' }
            }
          ]
        )
      end
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:agent_capabilities) { build(:agent_capabilities, :with_extensions) }

      it 'returns a JSON string with camel case keys' do
        expect(agent_capabilities.to_json).to match_json(<<~JSON)
          {
            "streaming": true,
            "pushNotifications": true,
            "stateTransitionHistory": false,
            "extensions": [
              {
                "uri": "https://a2a.dev/extensions/custom-maps-v1",
                "description": "Custom map styling and overlay capabilities",
                "required": false,
                "params": {
                  "maxLayers": 10,
                  "supportedFormats": ["geojson", "kml"]
                }
              },
              {
                "uri": "https://a2a.dev/extensions/auth-v1",
                "description": "Enhanced authentication for secure map data",
                "required": true,
                "params": {
                  "authType": "oauth2"
                }
              }
            ]
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:agent_capabilities) { build(:agent_capabilities, :with_extensions) }

      it 'returns a JSON string with snake case keys' do
        expect(agent_capabilities.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "streaming": true,
            "push_notifications": true,
            "state_transition_history": false,
            "extensions": [
              {
                "uri": "https://a2a.dev/extensions/custom-maps-v1",
                "description": "Custom map styling and overlay capabilities",
                "required": false,
                "params": {
                  "maxLayers": 10,
                  "supportedFormats": ["geojson", "kml"]
                }
              },
              {
                "uri": "https://a2a.dev/extensions/auth-v1",
                "description": "Enhanced authentication for secure map data",
                "required": true,
                "params": {
                  "authType": "oauth2"
                }
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
          "streaming": true,
          "pushNotifications": true,
          "stateTransitionHistory": false,
          "extensions": [
            {
              "uri": "https://a2a.dev/extensions/custom-v1",
              "description": "Custom extension",
              "required": true,
              "params": {
                "key": "value"
              }
            }
          ]
        }
      JSON
    end

    it 'initializes agent capabilities' do
      agent_capabilities = described_class.from_json(json_string)

      expect(agent_capabilities).to be_a(described_class)
    end

    it 'parses streaming' do
      agent_capabilities = described_class.from_json(json_string)

      expect(agent_capabilities.streaming).to be(true)
    end

    it 'parses push_notifications' do
      agent_capabilities = described_class.from_json(json_string)

      expect(agent_capabilities.push_notifications).to be(true)
    end

    it 'parses state_transition_history' do
      agent_capabilities = described_class.from_json(json_string)

      expect(agent_capabilities.state_transition_history).to be(false)
    end

    it 'parses extensions' do
      agent_capabilities = described_class.from_json(json_string)

      expect(agent_capabilities.extensions).to eq(
        [
          A2A::AgentExtension.new(
            uri: URI('https://a2a.dev/extensions/custom-v1'),
            description: 'Custom extension',
            required: true,
            params: { key: 'value' }
          )
        ]
      )
    end
  end
end
