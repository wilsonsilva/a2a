module A2A
  class CardBuilder
    def initialize
      @attributes = {
        skills: []
      }
      @current_skill = nil
      @capabilities = {}
    end

    def name(value)
      @attributes[:name] = value
    end

    def description(value)
      @attributes[:description] = value
    end

    def url(value)
      @attributes[:url] = value
    end

    def version(value)
      @attributes[:version] = value
    end

    def documentation_url(value)
      @attributes[:documentation_url] = value
    end

    def provider(organization, url = nil)
      @attributes[:provider] = AgentProvider.new(
        organization: organization,
        url: url
      )
    end

    def default_input_modes(modes)
      @attributes[:default_input_modes] = modes
    end

    def default_output_modes(modes)
      @attributes[:default_output_modes] = modes
    end

    def capabilities(&block)
      capabilities_builder = CapabilitiesBuilder.new
      capabilities_builder.instance_eval(&block)
      @attributes[:capabilities] = AgentCapabilities.new(capabilities_builder.attributes)
    end

    def authentication(schemes, credentials = nil)
      @attributes[:authentication] = AgentAuthentication.new(
        schemes: Array(schemes),
        credentials: credentials
      )
    end

    def skill(id, &block)
      skill_builder = SkillBuilder.new(id)
      skill_builder.instance_eval(&block)
      @attributes[:skills] << skill_builder.build
    end

    def build
      required_attrs = [:name, :url, :version]
      missing_attrs = required_attrs.select { |attr| @attributes[attr].nil? }

      if missing_attrs.any?
        raise ArgumentError, "Missing required attributes: #{missing_attrs.join(', ')}"
      end

      # Set default capabilities if not provided
      @attributes[:capabilities] ||= AgentCapabilities.new

      AgentCard.new(@attributes)
    end
  end
end
