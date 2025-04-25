# frozen_string_literal: true

require_relative '../../lib/a2a'

agent = A2A::Agent.build do
  card File.join(File.dirname(__FILE__), 'well-known/agent.json')
end

pp agent.card.to_h
