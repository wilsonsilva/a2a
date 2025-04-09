# frozen_string_literal: true

module A2A
  module Schema
    # Agent skill definition
    class AgentSkill < SchemaObject
      attr_accessor :id, :name, :description, :tags, :examples,
                    :input_modes, :output_modes

      # @param id [String] Skill ID
      # @param name [String] Human-readable name
      # @param description [String, nil] Optional description
      # @param tags [Array<String>, nil] Optional tags
      # @param examples [Array<String>, nil] Optional example prompts
      # @param input_modes [Array<String>, nil] Optional input mode overrides
      # @param output_modes [Array<String>, nil] Optional output mode overrides
      def initialize(id:, name:, description: nil, tags: nil, examples: nil,
                     input_modes: nil, output_modes: nil)
        @id = id
        @name = name
        @description = description
        @tags = tags
        @examples = examples
        @input_modes = input_modes
        @output_modes = output_modes
      end

      REQUIRED_FIELDS = [:id, :name].freeze
    end
  end
end