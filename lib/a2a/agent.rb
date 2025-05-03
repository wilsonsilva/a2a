module A2A
  class Agent
    include A2A::Hooks

    attr_reader :card

    def self.build(&block)
      agent = new

      if block_given?
        builder = AgentBuilder.new(agent)
        builder.instance_eval(&block)
      end

      agent
    end

    def initialize
      @task_manager = TaskManager.new
    end

    def card=(card_or_path)
      @card = case card_or_path
              when String
                if File.exist?(card_or_path)
                  AgentCard.from_json(File.read(card_or_path))
                else
                  raise ArgumentError, "Card file not found: #{card_or_path}"
                end
              when AgentCard
                card_or_path
              else
                raise ArgumentError, "Expected String path or AgentCard, got: #{card_or_path.class}"
              end
    end

    def handle_task(task)
      trigger_hook(:before_task, task)

      # Process the task
      result = @task_manager.process(task) do |t|
        trigger_hook(:on_task, t)
      end

      trigger_hook(:after_task, task)
      result
    end

    def handle_streaming_task(task, stream)
      trigger_hook(:on_task_subscribe, task, stream)
    end
  end
end
