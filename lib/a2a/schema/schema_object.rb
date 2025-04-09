module A2A
  module Schema
    # Base class for all schema objects, providing common serialization
    class SchemaObject
      # Convert the object to a hash suitable for JSON serialization
      # @return [Hash] Serializable hash
      def to_h
        result = {}
        instance_variables.each do |var|
          key = var.to_s.delete('@')
          value = instance_variable_get(var)

          # Skip nil values unless specifically needed
          next if value.nil? && !self.class::REQUIRED_FIELDS.include?(key.to_sym)

          # Handle array values
          if value.is_a?(Array)
            result[key] = value.map { |v| v.respond_to?(:to_h) ? v.to_h : v }
            # Handle nested schema objects
          elsif value.is_a?(SchemaObject)
            result[key] = value.to_h
            # Handle Time objects
          elsif value.is_a?(Time)
            result[key] = value.iso8601
          else
            result[key] = value
          end
        end
        result
      end

      # Convert the object to JSON
      # @param opts [Hash] JSON generation options
      # @return [String] JSON representation
      def to_json(opts = {})
        to_h.to_json(opts)
      end

      # Required fields that should be included even if nil
      REQUIRED_FIELDS = [].freeze
    end
  end
end
