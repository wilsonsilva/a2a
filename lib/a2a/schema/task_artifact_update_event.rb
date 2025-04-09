# frozen_string_literal: true

module A2A
  module Schema
    # Task artifact update event for streaming
    class TaskArtifactUpdateEvent < SchemaObject
      attr_accessor :id, :artifact, :final, :metadata

      # @param id [String] Task ID
      # @param artifact [Artifact] Updated or new artifact
      # @param final [Boolean] Whether this is the final update
      # @param metadata [Hash, nil] Optional metadata
      def initialize(id:, artifact:, final: false, metadata: nil)
        @id = id
        @artifact = artifact
        @final = final
        @metadata = metadata
      end

      REQUIRED_FIELDS = [:id, :artifact].freeze
    end
  end
end