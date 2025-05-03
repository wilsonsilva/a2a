# frozen_string_literal: true

require 'securerandom'

module A2A
  class Agent
    # Builder class for DSL
    class Builder
      attr_reader :agent

      def initialize
        @card_builder = CardBuilder.new
        @hooks = {}
      end

      # Gets, sets or builds the agent card
      #
      # @param arg [AgentCard, String, nil] The agent card, path to a JSON file, or nil if using block
      # @param block [Proc] Block containing the card definition if arg is nil
      # @return [AgentCard] The agent card instance
      #
      # @raise [Agent::AgentCardFileNotFoundError] If the provided card file path does not exist
      #
      def card(arg = nil, &block)
        @card ||= if arg.is_a?(AgentCard)
                    arg
                  elsif arg.is_a?(String)
                    if File.exist?(arg)
                      binding.irb
                      AgentCard.from_json(File.read(arg))
                    else
                      raise Agent::AgentCardFileNotFoundError, arg
                    end
                  elsif block_given?
                    @card_builder.instance_eval(&block)
                  else
                    @card
                  end
      end

      def before_task(&block)
        @hooks[:before_task] = block
      end

      def on_task_transition(&block)
        @hooks[:on_task_transition] = block
      end

      def after_task(&block)
        @hooks[:after_task] = block
      end

      def on_task(&block)
        @hooks[:on_task] = block
      end

      def on_task_subscribe(&block)
        @hooks[:on_task_subscribe] = block
      end

      def on_error(&block)
        @hooks[:on_error] = block
      end

      def agent
        @agent ||= Agent.new(
          card: @card_builder.build,
          hooks: @hooks
        )
      end
    end

    # Builder for agent card
    class CardBuilder
      def initialize
        @name = nil
        @url = nil
        @version = nil
        @description = nil
        @capabilities = {}
        @skills = []
        @default_input_modes = ['text/plain']
        @default_output_modes = ['text/plain']
      end

      def name(value)
        binding.irb
        @name = value
      end

      def url(value)
        @url = value
      end

      def version(value)
        @version = value
      end

      def description(value)
        @description = value
      end

      def capabilities(&block)
        builder = CapabilitiesBuilder.new
        builder.instance_eval(&block) if block_given?
        @capabilities = builder.to_h
      end

      def skill(id, &block)
        builder = SkillBuilder.new(id)
        builder.instance_eval(&block) if block_given?
        @skills << builder.build
      end

      def input_modes(modes)
        @default_input_modes = modes
      end

      def output_modes(modes)
        @default_output_modes = modes
      end

      def build
        binding.irb
        A2A::AgentCard.new(
          name: @name,
          description: @description,
          url: @url,
          provider: nil, # Optional provider details
          version: @version,
          capabilities: A2A::AgentCapabilities.new(@capabilities),
          default_input_modes: @default_input_modes,
          default_output_modes: @default_output_modes,
          skills: @skills
        )
      end
    end

    # Builder for capabilities
    class CapabilitiesBuilder
      attr_reader :streaming, :push_notifications, :state_transition_history

      def initialize
        @streaming = false
        @push_notifications = false
        @state_transition_history = false
      end

      def streaming(value)
        @streaming = value
      end

      def push_notifications(value)
        @push_notifications = value
      end

      def state_transition_history(value)
        @state_transition_history = value
      end

      def to_h
        {
          streaming: @streaming,
          push_notifications: @push_notifications,
          state_transition_history: @state_transition_history
        }
      end
    end

    # Builder for skills
    class SkillBuilder
      def initialize(id)
        @id = id
        @name = nil
        @description = nil
        @tags = []
        @examples = []
        @input_modes = nil
        @output_modes = nil
      end

      def name(value)
        @name = value
      end

      def description(value)
        @description = value
      end

      def tags(value)
        @tags = value
      end

      def examples(value)
        @examples = value
      end

      def input_modes(value)
        @input_modes = value
      end

      def output_modes(value)
        @output_modes = value
      end

      def build
        A2A::AgentSkill.new(
          id: @id,
          name: @name,
          description: @description,
          tags: @tags,
          examples: @examples,
          input_modes: @input_modes,
          output_modes: @output_modes
        )
      end
    end
  end
end
