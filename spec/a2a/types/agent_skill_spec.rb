# frozen_string_literal: true

RSpec.describe A2A::AgentSkill do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      # Attributes defined in the factory are snake case
      let(:agent_skill_attributes) { attributes_for(:agent_skill) }

      it 'initializes an agent skill' do
        agent_skill = described_class.new(agent_skill_attributes)

        expect(agent_skill).to be_a(described_class)
      end
    end

    context 'when given attributes with camel case keys' do
      let(:agent_skill_attributes) do
        attributes_for(:agent_skill).merge(
          inputModes: ['text/plain'],
          outputModes: %w[application/html video/mp4]
        )
      end

      it 'initializes an agent skill' do
        agent_skill = described_class.new(agent_skill_attributes)

        expect(agent_skill).to be_a(described_class)
      end
    end

    context 'when the optional attributes are missing' do
      let(:agent_skill_attributes) do
        attributes_for(:agent_skill).except(:examples, :input_modes, :output_modes)
      end

      it 'initializes an agent skill', :aggregate_failures do
        agent_skill = described_class.new(agent_skill_attributes)

        expect(agent_skill).to be_a(described_class)
        expect(agent_skill.examples).to be_nil
        expect(agent_skill.input_modes).to be_nil
        expect(agent_skill.output_modes).to be_nil
      end
    end

    context 'when the required attributes are missing' do
      let(:agent_skill_attributes) { attributes_for(:agent_skill).except(:id, :name, :description, :tags) }

      it 'raises an error' do
        expect { described_class.new(agent_skill_attributes) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    let(:agent_skill) { build(:agent_skill) }

    it 'converts the agent skill to a hash' do
      expect(agent_skill.to_h).to eq(
        id: 'route-planner',
        name: 'Route planning',
        description: 'Helps plan routing between two locations',
        tags: %w[maps routing navigation],
        examples: ['plan my route from Sunnyvale to Mountain View'],
        input_modes: ['text/plain'],
        output_modes: %w[application/html video/mp4],
        security: nil
      )
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:agent_skill) { build(:agent_skill) }

      it 'returns a JSON string with camel case keys' do
        expect(agent_skill.to_json).to match_json(<<~JSON)
          {
            "id": "route-planner",
            "name": "Route planning",
            "description": "Helps plan routing between two locations",
            "tags": ["maps", "routing", "navigation"],
            "examples": ["plan my route from Sunnyvale to Mountain View"],
            "inputModes": ["text/plain"],
            "outputModes": ["application/html", "video/mp4"]
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:agent_skill) { build(:agent_skill) }

      it 'returns a JSON string with snake case keys' do
        expect(agent_skill.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "id": "route-planner",
            "name": "Route planning",
            "description": "Helps plan routing between two locations",
            "tags": ["maps", "routing", "navigation"],
            "examples": ["plan my route from Sunnyvale to Mountain View"],
            "input_modes": ["text/plain"],
            "output_modes": ["application/html", "video/mp4"]
          }
        JSON
      end
    end
  end

  describe '.from_json' do
    let(:json_string) do
      <<~JSON
        {
          "id": "route-planner",
          "name": "Route planning",
          "description": "Helps plan routing between two locations",
          "tags": ["maps", "routing", "navigation"],
          "examples": ["plan my route from Sunnyvale to Mountain View"],
          "inputModes": ["text/plain"],
          "outputModes": ["application/html", "video/mp4"]
        }
      JSON
    end

    it 'initializes an agent skill' do
      agent_skill = described_class.from_json(json_string)

      expect(agent_skill).to be_a(described_class)
    end

    it 'parses id' do
      agent_skill = described_class.from_json(json_string)

      expect(agent_skill.id).to eq('route-planner')
    end

    it 'parses name' do
      agent_skill = described_class.from_json(json_string)

      expect(agent_skill.name).to eq('Route planning')
    end

    it 'parses description' do
      agent_skill = described_class.from_json(json_string)

      expect(agent_skill.description).to eq('Helps plan routing between two locations')
    end

    it 'parses tags' do
      agent_skill = described_class.from_json(json_string)

      expect(agent_skill.tags).to eq(%w[maps routing navigation])
    end

    it 'parses examples' do
      agent_skill = described_class.from_json(json_string)

      expect(agent_skill.examples).to eq(['plan my route from Sunnyvale to Mountain View'])
    end

    it 'parses input_modes' do
      agent_skill = described_class.from_json(json_string)

      expect(agent_skill.input_modes).to eq(['text/plain'])
    end

    it 'parses output_modes' do
      agent_skill = described_class.from_json(json_string)

      expect(agent_skill.output_modes).to eq(%w[application/html video/mp4])
    end
  end
end
