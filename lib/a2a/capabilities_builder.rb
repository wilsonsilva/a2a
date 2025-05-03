module A2A
  class CapabilitiesBuilder
    attr_reader :attributes

    def initialize
      @attributes = {}
    end

    def streaming(value)
      @attributes[:streaming] = value
    end

    def push_notifications(value)
      @attributes[:push_notifications] = value
    end

    def state_transition_history(value)
      @attributes[:state_transition_history] = value
    end
  end
end
