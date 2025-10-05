# frozen_string_literal: true

module A2A
  # Defines base properties common to all message or artifact parts.
  class PartBase < ProtocolStruct
    # @return [Hash<String, Object>] Optional metadata associated with this part.
    attribute? :metadata, Types::Hash.map(Types::String, Types::Any).optional
  end
end
