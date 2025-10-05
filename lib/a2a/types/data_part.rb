# frozen_string_literal: true

module A2A
  # Represents a structured data segment (e.g., JSON) within a message or artifact.
  class DataPart < PartBase
    # @return [String] The type of this part, used as a discriminator. Always 'data'.
    attribute :kind, Types::String.constant('data')

    # @return [Hash] The structured data content.
    attribute :data, Types::Hash
  end
end
