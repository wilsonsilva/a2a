# frozen_string_literal: true

require_relative 'a2a/version'
require_relative 'a2a/types'

# Encapsulates all the gem's logic
module A2A
  # @!visibility private
  # @return [Dry::Inflector] The inflector instance used for camelizing keys
  INFLECTOR = Dry::Inflector.new
end
