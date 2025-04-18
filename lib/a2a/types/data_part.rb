# frozen_string_literal: true

module A2A
  # Represents a part of a message containing structured data (JSON).
  class DataPart < ProtocolStruct
    # @return [String] Type identifier for this part.
    attribute :type, Types::String.constant('data')

    # @return [Hash] The structured data content as a JSON object.
    attribute :data, Types::Hash

    # @return [Hash, nil] Optional metadata associated with this data part.
    attribute? :metadata, Types::Hash.optional
  end
end
