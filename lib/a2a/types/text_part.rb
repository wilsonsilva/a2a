# frozen_string_literal: true

module A2A
  # Represents a text segment within a message or artifact.
  class TextPart < PartBase
    # @return [String] The type of this part, used as a discriminator. Always 'text'.
    attribute :kind, Types::String.constant('text')

    # @return [String] The string content of the text part.
    attribute :text, Types::String
  end
end
