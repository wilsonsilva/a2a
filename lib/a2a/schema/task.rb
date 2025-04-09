# frozen_string_literal: true

module A2A
  module Schema
    # Task object representation
    class Task < SchemaObject
      attr_accessor :id, :session_id, :status, :artifacts, :metadata

      # @param id [String] Unique task ID
      # @param status [TaskStatus] Current task status
      # @param session_id [String, nil] Optional session ID
      # @param artifacts [Array<Artifact>, nil] Optional artifacts
      # @param metadata [Hash, nil] Optional metadata
      def initialize(id:, status:, session_id: nil, artifacts: nil, metadata: nil)
        @id = id
        @session_id = session_id
        @status = status
        @artifacts = artifacts || []
        @metadata = metadata
      end

      REQUIRED_FIELDS = [:id, :status].freeze
    end
  end
end