# frozen_string_literal: true

module A2A
  module Schema
    # Task status update event for streaming
    class TaskStatusUpdateEvent < SchemaObject
      attr_accessor :id, :status, :final, :metadata

      # @param id [String] Task ID
      # @param status [TaskStatus] Updated status
      # @param final [Boolean] Whether this is the final update
      # @param metadata [Hash, nil] Optional metadata
      def initialize(id:, status:, final: false, metadata: nil)
        @id = id
        @status = status
        @final = final
        @metadata = metadata
      end

      REQUIRED_FIELDS = [:id, :status].freeze
    end
  end
end