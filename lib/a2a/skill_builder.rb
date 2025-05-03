module A2A
  class SkillBuilder
    attr_reader :attributes

    def initialize(id)
      @attributes = { id: id }
    end

    def name(value)
      @attributes[:name] = value
    end

    def description(value)
      @attributes[:description] = value
    end

    def tags(values)
      @attributes[:tags] = values
    end

    def examples(values)
      @attributes[:examples] = values
    end

    def input_modes(modes)
      @attributes[:input_modes] = modes
    end

    def output_modes(modes)
      @attributes[:output_modes] = modes
    end

    def build
      # Validate required attributes
      unless @attributes[:name]
        raise ArgumentError, "Skill name is required"
      end

      AgentSkill.new(@attributes)
    end
  end
end
