module A2A
  class AgentBuilder
    def initialize(agent)
      @agent = agent
      @card_builder = nil
    end

    def card(card_or_path = nil, &block)
      if block_given?
        @card_builder = CardBuilder.new
        @card_builder.instance_eval(&block)
        @agent.card = @card_builder.build
      elsif card_or_path
        @agent.card = card_or_path
      else
        raise ArgumentError, "Expected card path, AgentCard instance, or block"
      end
    end

    def before_task(&block)
      @agent.register_hook(:before_task, &block)
    end

    def on_task(&block)
      @agent.register_hook(:on_task, &block)
    end

    def on_task_transition(&block)
      @agent.register_hook(:on_task_transition, &block)
    end

    def after_task(&block)
      @agent.register_hook(:after_task, &block)
    end

    def on_task_subscribe(&block)
      @agent.register_hook(:on_task_subscribe, &block)
    end
  end
end
