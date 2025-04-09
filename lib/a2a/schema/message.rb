# frozen_string_literal: true

module A2A
  module Schema
    # Message object exchanged between client and agent
    class Message < SchemaObject
      attr_accessor :role, :parts, :metadata

      # @param role [String] 'user' or 'agent'
      # @param parts [Array<Part>] Message parts
      # @param metadata [Hash, nil] Optional metadata
      def initialize(role:, parts:, metadata: nil)
        @role = role
        @parts = parts
        @metadata = metadata
      end

      # Creates a user message with a single text part
      # @param text [String] The text content
      # @param metadata [Hash, nil] Optional metadata
      # @return [Message] A new user message
      def self.user_text(text, metadata: nil)
        new(
          role: 'user',
          parts: [TextPart.new(text: text)],
          metadata: metadata
        )
      end

      # Creates an agent message with a single text part
      # @param text [String] The text content
      # @param metadata [Hash, nil] Optional metadata
      # @return [Message] A new agent message
      def self.agent_text(text, metadata: nil)
        new(
          role: 'agent',
          parts: [TextPart.new(text: text)],
          metadata: metadata
        )
      end

      REQUIRED_FIELDS = [:role, :parts].freeze
    end
  end
end