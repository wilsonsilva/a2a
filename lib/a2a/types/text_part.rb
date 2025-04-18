# frozen_string_literal: true

module A2A
  # Represents a part of a message containing text content.
  class TextPart < ProtocolStruct
    # @return [String] Type identifier for this part.
    attribute :type, Types::String.constant('text')

    # @return [String] The text content.
    attribute :text, Types::String

    # @return [Hash, nil] Optional metadata associated with this text part.
    attribute? :metadata, Types::Hash.optional
  end
end
