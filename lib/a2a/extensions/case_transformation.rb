# frozen_string_literal: true

module A2A
  module Extensions
    # Allows a dry-struct to be instantiated and serialized with camelCase keys.
    module CaseTransformation
      def self.included(base)
        base.class_eval do
          # Transform keys to snake_case symbols when initializing the struct
          transform_keys { |key| INFLECTOR.underscore(key.to_s).to_sym }
        end
      end

      # Converts hash keys from snake_case to camelCase recursively
      #
      # @param value [Object] The value to convert
      #
      # @return [Object] The value with camelized keys if applicable
      #
      def camelize(value)
        case value
        when Array
          value.map { |item| camelize(item) }
        when Hash
          value.to_h do |key, v|
            [INFLECTOR.camelize_lower(key.to_s).to_sym, camelize(v)]
          end
        else
          value
        end
      end

      # Serializes the object to JSON with an option for camelCase formatting
      #
      # @param camel_case [Boolean] Whether to convert keys to camelCase
      #
      # @return [String] JSON representation of the object
      #
      def to_json(camel_case: true, **)
        data = to_h
        data = camelize(data) if camel_case
        data.to_json(**)
      end
    end
  end
end
