# frozen_string_literal: true

RSpec.describe A2A::AgentProvider do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      let(:agent_provider_attributes) { attributes_for(:agent_provider) }

      it 'initializes an agent provider' do
        agent_provider = described_class.new(agent_provider_attributes)

        expect(agent_provider).to be_a(described_class)
      end
    end

    context 'when the optional attributes are missing' do
      let(:agent_provider_attributes) do
        attributes_for(:agent_provider).except(:url)
      end

      it 'initializes an agent provider', :aggregate_failures do
        agent_provider = described_class.new(agent_provider_attributes)

        expect(agent_provider).to be_a(described_class)
        expect(agent_provider.url).to be_nil
      end
    end

    context 'when the required attributes are missing' do
      let(:agent_provider_attributes) do
        attributes_for(:agent_provider).except(:organization)
      end

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
        url: 'https://google.com'
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
  end
end
