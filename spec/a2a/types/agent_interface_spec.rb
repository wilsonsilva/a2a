# frozen_string_literal: true

RSpec.describe A2A::AgentInterface do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      # Attributes defined in the factory are snake case
      let(:agent_interface_attributes) { attributes_for(:agent_interface) }

      it 'initializes an agent interface' do
        agent_interface = described_class.new(agent_interface_attributes)

        expect(agent_interface).to be_a(described_class)
      end
    end

    context 'when the required attributes are missing' do
      let(:agent_interface_attributes) do
        attributes_for(:agent_interface).except(:url)
      end

      it 'raises an error' do
        expect { described_class.new(agent_interface_attributes) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    let(:agent_interface) { build(:agent_interface, :jsonrpc) }

    it 'converts the agent interface to a hash' do
      expect(agent_interface.to_h).to eq(
        url: URI('https://georoute-agent.example.com/a2a/v1'),
        transport: 'JSONRPC'
      )
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:agent_interface) { build(:agent_interface, :grpc) }

      it 'returns a JSON string with camel case keys' do
        expect(agent_interface.to_json).to match_json(<<~JSON)
          {
            "url": "https://georoute-agent.example.com/a2a/grpc",
            "transport": "GRPC"
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:agent_interface) { build(:agent_interface, :http_json) }

      it 'returns a JSON string with snake case keys' do
        expect(agent_interface.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "url": "https://georoute-agent.example.com/a2a/json",
            "transport": "HTTP+JSON"
          }
        JSON
      end
    end
  end

  describe '.from_json' do
    let(:json_string) do
      <<~JSON
        {
          "url": "https://georoute-agent.example.com/a2a/v1",
          "transport": "JSONRPC"
        }
      JSON
    end

    it 'initializes an agent interface' do
      agent_interface = described_class.from_json(json_string)

      expect(agent_interface).to be_a(described_class)
    end

    it 'parses url' do
      agent_interface = described_class.from_json(json_string)

      expect(agent_interface.url).to eq(URI('https://georoute-agent.example.com/a2a/v1'))
    end

    it 'parses transport' do
      agent_interface = described_class.from_json(json_string)

      expect(agent_interface.transport).to eq('JSONRPC')
    end
  end
end
