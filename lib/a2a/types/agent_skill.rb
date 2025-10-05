# frozen_string_literal: true

module A2A
  # Defines a specific skill or capability offered by an agent.
  class AgentSkill < ProtocolStruct
    # @return [String] Unique identifier for the skill.
    attribute :id, Types::String

    # @return [String] Human-readable name of the skill.
    attribute :name, Types::String

    # @return [String] A detailed description of the skill, intended to help clients or users
    #   understand its purpose and functionality.
    attribute :description, Types::String

    # @return [Array<String>] A set of keywords describing the skill's capabilities.
    attribute :tags, Types::Array.of(Types::String)

    # @return [Array<String>, nil] Optional list of example inputs or use cases for the skill.
    attribute? :examples, Types::Array.of(Types::String).optional

    # @return [Array<String>, nil] Optional list of input modes supported by this skill, overriding agent defaults.
    attribute? :input_modes, Types::Array.of(Types::String).optional

    # @return [Array<String>, nil] Optional list of output modes supported by this skill, overriding agent defaults.
    attribute? :output_modes, Types::Array.of(Types::String).optional

    # @return [Array<Hash>, nil] Security schemes necessary for the agent to leverage this skill.
    #   As in the overall AgentCard.security, this list represents a logical OR of security
    #   requirement objects. Each object is a set of security schemes that must be used together
    #   (a logical AND).
    attribute? :security, Types::Array.of(Types::Hash.map(Types::String, Types::Array.of(Types::String))).optional
  end
end
