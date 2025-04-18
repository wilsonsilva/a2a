# frozen_string_literal: true

module A2A
  # Defines a specific skill or capability offered by an agent.
  class AgentSkill < ProtocolStruct
    # @return [String] Unique identifier for the skill.
    attribute :id, Types::String

    # @return [String] Human-readable name of the skill.
    attribute :name, Types::String

    # @return [String, nil] Optional description of the skill.
    attribute? :description, Types::String.optional

    # @return [Array<String>, nil] Optional list of tags associated with the skill for categorization.
    attribute? :tags, Types::Array.of(Types::String).optional

    # @return [Array<String>, nil] Optional list of example inputs or use cases for the skill.
    attribute? :examples, Types::Array.of(Types::String).optional

    # @return [Array<String>, nil] Optional list of input modes supported by this skill, overriding agent defaults.
    attribute? :input_modes, Types::Array.of(Types::String).optional

    # @return [Array<String>, nil] Optional list of output modes supported by this skill, overriding agent defaults.
    attribute? :output_modes, Types::Array.of(Types::String).optional
  end
end
