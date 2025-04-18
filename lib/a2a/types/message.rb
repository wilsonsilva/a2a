# frozen_string_literal: true

module A2A
  # Represents a message exchanged between a user and an agent.
  class Message < ProtocolStruct
    # @return [String] The role of the sender (user or agent).
    attribute :role, Types::String.enum('user', 'agent')

    # @return [Array<Part>] The content of the message, composed of one or more parts.
    attribute :parts, Types::Array.of(Types::Constructor(Part))

    # @return [Hash, nil] Optional metadata associated with the message.
    attribute? :metadata, Types::Hash.optional
  end
end
