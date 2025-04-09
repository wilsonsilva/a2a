# frozen_string_literal: true

module A2A
  module Schema
    # Task ID parameters (base for several operations)
    class TaskIdParams < SchemaObject
      attr_accessor :id, :metadata

      # @param id [String] Task ID
      # @param metadata [Hash, nil] Optional metadata
      def initialize(id:, metadata: nil)
        @id = id
        @metadata = metadata
      end

      REQUIRED_FIELDS = [:id].freeze
    end
  end
end