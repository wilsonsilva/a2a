# frozen_string_literal: true

module A2A
  module Schema
    # Data part for structured data
    class DataPart < Part
      attr_accessor :data, :type

      # @param data [Hash] The structured data
      # @param metadata [Hash, nil] Optional metadata
      def initialize(data:, metadata: nil)
        super(metadata: metadata)
        @type = 'data'
        @data = data
      end

      REQUIRED_FIELDS = [:type, :data].freeze
    end
  end
end