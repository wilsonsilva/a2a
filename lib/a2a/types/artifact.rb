# frozen_string_literal: true

module A2A
  # Represents an artifact generated or used by a task, potentially composed of multiple parts.
  class Artifact < ProtocolStruct
    # @return [String, nil] Optional name for the artifact.
    attribute? :name, Types::String.optional

    # @return [String, nil] Optional description of the artifact.
    attribute? :description, Types::String.optional

    # @return [Array<Part>] The constituent parts of the artifact.
    attribute :parts, Types::Array.of(Types::Constructor(Part))

    # @return [Integer, nil] Optional index for ordering artifacts, especially relevant in streaming or updates.
    attribute? :index, Types::Integer.default(0)

    # @return [Boolean, nil] Optional flag indicating if this artifact content should append to previous
    # content (for streaming).
    attribute? :append, Types::Bool.optional

    # @return [Hash, nil] Optional metadata associated with the artifact.
    attribute? :metadata, Types::Hash.optional

    # @return [Boolean, nil] Optional flag indicating if this is the last chunk of data for this
    # artifact (for streaming).
    attribute? :last_chunk, Types::Bool.optional
  end
end
