# frozen_string_literal: true

RSpec.describe A2A::AgentCardSignature do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      # Attributes defined in the factory are snake case
      let(:agent_card_signature_attributes) { attributes_for(:agent_card_signature) }

      it 'initializes an agent card signature' do
        agent_card_signature = described_class.new(agent_card_signature_attributes)

        expect(agent_card_signature).to be_a(described_class)
      end
    end

    context 'when the optional attributes are missing' do
      let(:agent_card_signature_attributes) do
        attributes_for(:agent_card_signature).except(:header)
      end

      it 'initializes an agent card signature', :aggregate_failures do
        agent_card_signature = described_class.new(agent_card_signature_attributes)

        expect(agent_card_signature).to be_a(described_class)
        expect(agent_card_signature.header).to be_nil
      end
    end

    context 'when the required attributes are missing' do
      let(:agent_card_signature_attributes) do
        attributes_for(:agent_card_signature).except(:protected, :signature)
      end

      it 'raises an error' do
        expect { described_class.new(agent_card_signature_attributes) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    context 'without header' do
      let(:agent_card_signature) { build(:agent_card_signature, :example_signature) }

      it 'converts the agent card signature to a hash' do
        expect(agent_card_signature.to_h).to eq(
          protected: 'eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMSIsImprdSI6Imh0dHBzOi8vZXhh' \
                     'bXBsZS5jb20vYWdlbnQvandrcy5qc29uIn0',
          signature: 'QFdkNLNszlGj3z3u0YQGt_T9LixY3qtdQpZmsTdDHDe3fXV9y9-B3m2-XgCpzuhiLt8E0tV6HXoZKHv4GtHgKQ',
          header: nil
        )
      end
    end

    context 'with header' do
      let(:agent_card_signature) { build(:agent_card_signature, :with_header) }

      it 'converts the agent card signature to a hash' do
        expect(agent_card_signature.to_h).to eq(
          protected: 'eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMiJ9',
          signature: 'abc123xyz789signature',
          header: { 'kid' => 'key-2', 'custom' => 'value' }
        )
      end
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:agent_card_signature) { build(:agent_card_signature, :example_signature) }

      it 'returns a JSON string with camel case keys' do
        expect(agent_card_signature.to_json).to match_json(<<~JSON)
          {
            "protected": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMSIsImprdSI6Imh0dHBzOi8vZXhhbXBsZS5jb20vYWdlbnQvandrcy5qc29uIn0",
            "signature": "QFdkNLNszlGj3z3u0YQGt_T9LixY3qtdQpZmsTdDHDe3fXV9y9-B3m2-XgCpzuhiLt8E0tV6HXoZKHv4GtHgKQ"
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:agent_card_signature) { build(:agent_card_signature, :with_header) }

      it 'returns a JSON string with snake case keys' do
        expect(agent_card_signature.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "protected": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMiJ9",
            "signature": "abc123xyz789signature",
            "header": {
              "kid": "key-2",
              "custom": "value"
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
          "protected": "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMSJ9",
          "signature": "testSignature123",
          "header": {
            "kid": "key-1",
            "custom": "value"
          }
        }
      JSON
    end

    it 'initializes an agent card signature' do
      agent_card_signature = described_class.from_json(json_string)

      expect(agent_card_signature).to be_a(described_class)
    end

    it 'parses protected' do
      agent_card_signature = described_class.from_json(json_string)

      expect(agent_card_signature.protected).to eq('eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMSJ9')
    end

    it 'parses signature' do
      agent_card_signature = described_class.from_json(json_string)

      expect(agent_card_signature.signature).to eq('testSignature123')
    end

    it 'parses header' do
      agent_card_signature = described_class.from_json(json_string)

      expect(agent_card_signature.header).to eq(
        kid: 'key-1',
        custom: 'value'
      )
    end
  end
end
