# frozen_string_literal: true

module A2A
  module Schema
    # File part for messages and artifacts
    class FilePart < Part
      attr_accessor :file, :type

      # @param file [Hash] The file content with name, mimeType, bytes/uri
      # @param metadata [Hash, nil] Optional metadata
      def initialize(file:, metadata: nil)
        super(metadata: metadata)
        @type = 'file'
        @file = file
      end

      REQUIRED_FIELDS = [:type, :file].freeze
    end
  end
end