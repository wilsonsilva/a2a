module A2A
  module Hooks
    def self.included(base)
      base.class_eval do
        attr_reader :hooks
      end
    end

    def initialize
      @hooks = {
        before_task: [],
        on_task: [],
        on_task_transition: [],
        after_task: [],
        on_task_subscribe: []
      }
      super
    end

    def register_hook(name, &block)
      @hooks[name] << block if block_given?
    end

    def trigger_hook(name, *args)
      @hooks[name].each { |hook| hook.call(*args) }
    end
  end
end
