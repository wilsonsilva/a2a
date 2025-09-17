# frozen_string_literal: true

require 'dry/inflector'
require 'zeitwerk'
require 'jsonrpc'

# Encapsulates all the gem's logic
module A2A
  # @!visibility private
  # @return [Dry::Inflector] The inflector instance used for camelizing keys
  INFLECTOR = Dry::Inflector.new
end

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'a2a' => 'A2A',
  'json_deserialization' => 'JSONDeserialization'
)
loader.collapse("#{__dir__}/a2a/types")
loader.enable_reloading
loader.setup
loader.eager_load
