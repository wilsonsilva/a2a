# frozen_string_literal: true

# a2a/examples/agent_cards/fully_typed_instance.rb

require '../lib/a2a'

require_relative '../../lib/a2a'

agent = A2A::Agent.build do
  card File.join(File.dirname(__FILE__), 'well-known/agent.json')
end

pp agent.card.to_h
