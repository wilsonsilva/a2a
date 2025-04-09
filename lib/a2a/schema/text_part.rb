# frozen_string_literal: true

module A2A
  module Schema
    # Text part for messages
    class TextPart < Part
      attr_accessor :text, :type

      # @param text [String] The text content
      # @param metadata [Hash, nil] Optional metadata
      def initialize(text:, metadata: nil)
        super(metadata: metadata)
        @type = 'text'
        @text = text
      end

      REQUIRED_FIELDS = [:type, :text].freeze
    end
  end
end