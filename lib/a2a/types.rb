# frozen_string_literal: true

require 'dry-types'

module A2A
  # @!visibility private
  module Types
    include Dry.Types()

    Dry::Types.define_builder(:constant) { |type, value| type.default(value).enum(value) }
  end
end
