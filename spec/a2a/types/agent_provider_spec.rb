# frozen_string_literal: true

RSpec.describe A2A::AgentProvider do
  describe '.new' do
    context 'when given all required attributes' do
      let(:agent_provider_attributes) { attributes_for(:agent_provider) }

      it 'initializes an agent provider' do
        agent_provider = described_class.new(agent_provider_attributes)

        expect(agent_provider).to be_a(described_class)
      end
    end

    context 'when the required attributes are missing' do
      let(:agent_provider_attributes) { attributes_for(:agent_provider).except(:organization, :url) }

      it 'raises an error' do
        expect { described_class.new(agent_provider_attributes) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    let(:agent_provider) { build(:agent_provider) }

    it 'converts the agent provider to a hash' do
      expect(agent_provider.to_h).to eq(
        organization: 'Google',
        url: URI('https://google.com')
      )
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:agent_provider) { build(:agent_provider) }

      it 'returns a JSON string with camel case keys' do
        expect(agent_provider.to_json).to match_json(<<~JSON)
          {
            "organization": "Google",
            "url": "https://google.com"
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:agent_provider) { build(:agent_provider) }

      it 'returns a JSON string with snake case keys' do
        expect(agent_provider.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "organization": "Google",
            "url": "https://google.com"
          }
        JSON
      end
    end
  end

  describe '.from_json' do
    let(:json_string) do
      <<~JSON
        {
          "organization": "Google",
          "url": "https://google.com"
        }
      JSON
    end

    it 'initializes an agent provider' do
      agent_provider = described_class.from_json(json_string)

      expect(agent_provider).to be_a(described_class)
    end

    it 'parses organization' do
      agent_provider = described_class.from_json(json_string)

      expect(agent_provider.organization).to eq('Google')
    end

    it 'parses url' do
      agent_provider = described_class.from_json(json_string)

      expect(agent_provider.url).to eq(URI('https://google.com'))
    end
  end
end
