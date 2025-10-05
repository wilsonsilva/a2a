# frozen_string_literal: true

RSpec.describe A2A::AgentExtension do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      # Attributes defined in the factory are snake case
      let(:agent_extension_attributes) { attributes_for(:agent_extension) }

      it 'initializes an agent extension' do
        agent_extension = described_class.new(agent_extension_attributes)

        expect(agent_extension).to be_a(described_class)
      end
    end

    context 'when the optional attributes are missing' do
      let(:agent_extension_attributes) do
        {
          uri: URI('https://a2a.dev/extensions/test')
        }
      end

      it 'initializes an agent extension with default attributes', :aggregate_failures do
        agent_extension = described_class.new(agent_extension_attributes)

        expect(agent_extension).to be_a(described_class)
        expect(agent_extension.description).to be_nil
        expect(agent_extension.required).to be(false)
        expect(agent_extension.params).to be_nil
      end
    end

    context 'when the required attributes are missing' do
      let(:agent_extension_attributes) do
        {
          description: 'Missing URI'
        }
      end

      it 'raises an error' do
        expect { described_class.new(agent_extension_attributes) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    let(:agent_extension) { build(:agent_extension, :optional_extension) }

    it 'converts the agent extension to a hash' do
      expect(agent_extension.to_h).to eq(
        uri: URI('https://a2a.dev/extensions/custom-maps-v1'),
        description: 'Custom map styling and overlay capabilities',
        required: false,
        params: { 'maxLayers' => 10, 'supportedFormats' => %w[geojson kml] }
      )
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:agent_extension) { build(:agent_extension, :required_extension) }

      it 'returns a JSON string with camel case keys' do
        expect(agent_extension.to_json).to match_json(<<~JSON)
          {
            "uri": "https://a2a.dev/extensions/auth-v1",
            "description": "Enhanced authentication for secure map data",
            "required": true,
            "params": {
              "authType": "oauth2"
            }
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:agent_extension) { build(:agent_extension, :optional_extension) }

      it 'returns a JSON string with snake case keys' do
        expect(agent_extension.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "uri": "https://a2a.dev/extensions/custom-maps-v1",
            "description": "Custom map styling and overlay capabilities",
            "required": false,
            "params": {
              "maxLayers": 10,
              "supportedFormats": ["geojson", "kml"]
            }
          }
        JSON
      end
    end
  end

  describe '.from_json' do
    let(:json_string) do
      <<~JSON
        {
          "uri": "https://a2a.dev/extensions/test",
          "description": "Test extension",
          "required": true,
          "params": {
            "key": "value"
          }
        }
      JSON
    end

    it 'initializes an agent extension' do
      agent_extension = described_class.from_json(json_string)

      expect(agent_extension).to be_a(described_class)
    end

    it 'parses uri' do
      agent_extension = described_class.from_json(json_string)

      expect(agent_extension.uri).to eq(URI('https://a2a.dev/extensions/test'))
    end

    it 'parses description' do
      agent_extension = described_class.from_json(json_string)

      expect(agent_extension.description).to eq('Test extension')
    end

    it 'parses required' do
      agent_extension = described_class.from_json(json_string)

      expect(agent_extension.required).to be(true)
    end

    it 'parses params' do
      agent_extension = described_class.from_json(json_string)

      expect(agent_extension.params).to eq(
        key: 'value'
      )
    end
  end
end
