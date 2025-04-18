# frozen_string_literal: true

RSpec.describe A2A::AgentCapabilities do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      let(:agent_capabilities_attributes) { attributes_for(:agent_capabilities) }

      it 'initializes agent capabilities' do
        agent_capabilities = described_class.new(agent_capabilities_attributes)

        expect(agent_capabilities).to be_a(described_class)
      end
    end

    context 'when given attributes with camel case keys' do
      let(:agent_capabilities_attributes) do
        {
          streaming: false,
          pushNotifications: false,
          stateTransitionHistory: false
        }
      end

      it 'initializes agent capabilities' do
        agent_capabilities = described_class.new(agent_capabilities_attributes)

        expect(agent_capabilities).to be_a(described_class)
      end
    end

    context 'when the default attributes are missing' do
      let(:agent_capabilities_attributes) { {} }

      it 'initializes agent capabilities with default attributes', :aggregate_failures do
        agent_capabilities = described_class.new(agent_capabilities_attributes)

        expect(agent_capabilities).to be_a(described_class)
        expect(agent_capabilities.streaming).to be(false)
        expect(agent_capabilities.push_notifications).to be(false)
        expect(agent_capabilities.state_transition_history).to be(false)
      end
    end

    context 'when the default attributes overridden' do
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
    let(:agent_capabilities) { build(:agent_capabilities) }

    it 'converts the agent capabilities to a hash' do
      expect(agent_capabilities.to_h).to eq(
        streaming: false,
        push_notifications: false,
        state_transition_history: false
      )
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:agent_capabilities) { build(:agent_capabilities) }

      it 'returns a JSON string with camel case keys' do
        expect(agent_capabilities.to_json).to match_json(<<~JSON)
          {
            "streaming": false,
            "pushNotifications": false,
            "stateTransitionHistory": false
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:agent_capabilities) { build(:agent_capabilities) }

      it 'returns a JSON string with snake case keys' do
        expect(agent_capabilities.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "streaming": false,
            "push_notifications": false,
            "state_transition_history": false
          }
        JSON
      end
    end
  end

  describe '.from_json' do
    let(:json_string) do
      <<~JSON
        {
          "streaming": false,
          "pushNotifications": false,
          "stateTransitionHistory": false
        }
      JSON
    end

    it 'initializes agent capabilities' do
      agent_capabilities = described_class.from_json(json_string)

      expect(agent_capabilities).to be_a(described_class)
    end
  end
end
