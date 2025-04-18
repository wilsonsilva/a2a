# frozen_string_literal: true

require 'json'

module A2A
  module Extensions
    # Provides JSON deserialization capabilities to a class
    module JSONDeserialization
      # @!visibility private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Class methods added to the class that includes JsonDeserialization
      module ClassMethods
        # Creates a new instance from a JSON string
        #
        # @param json [String] JSON string to parse
        # @return [ProtocolStruct] A new instance of the appropriate class
        #
        # @example Create a Google Maps Agent Card from JSON
        #   json_string = <<~JSON
        #     {
        #       "name": "Google Maps Agent",
        #       "description": "Plan routes, remember places, and generate directions",
        #       "url": "https://maps-agent.google.com",
        #       "provider": {
        #         "organization": "Google",
        #         "url": "https://google.com"
        #       },
        #       "version": "1.0.0",
        #       "capabilities": {
        #         "streaming": true,
        #         "pushNotifications": false
        #       },
        #       "skills": [
        #         {
        #           "id": "route-planner",
        #           "name": "Route planning",
        #           "description": "Helps plan routing between two locations"
        #         }
        #       ]
        #     }
        #   JSON
        #   agent_card = A2A::AgentCard.from_json(json_string)
        #
        def from_json(json)
          new(JSON.parse(json))
        end
      end
    end
  end
end
