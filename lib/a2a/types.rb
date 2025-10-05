# frozen_string_literal: true

require 'dry-types'

module A2A
  # @!visibility private
  module Types
    include Dry.Types()

    Dry::Types.define_builder(:constant) { |type, value| type.default(value).enum(value) }

    # Custom URI type that accepts both String and URI objects
    # and ensures the result is always a URI object
    URI = Types.Constructor(::URI) do |value|
      case value
      when ::URI
        value
      when String
        ::URI.parse(value)
      else
        raise ArgumentError, "Expected String or URI, got #{value.class}"
      end
    end
  end
end
