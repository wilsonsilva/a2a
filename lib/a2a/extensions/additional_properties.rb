# frozen_string_literal: true

module A2A
  module Extensions
    # Allows a dry-struct to have additional properties beyond the defined schema.
    # Limitations: the +attributes+ method does not return additional properties.
    module AdditionalProperties
      # @!visibility private
      # @return [Hash] Storage for additional properties not defined in the schema
      attr_reader :additional_properties

      # @!visibility private
      def self.included(base)
        base.extend(ClassMethods)
      end

      # Initialize with empty additional properties
      def initialize(*)
        super
        @additional_properties ||= {}
      end

      # Access additional properties via method_missing
      #
      # @param method_name [Symbol] Method name corresponding to property
      # @param args [Array] Method arguments (unused)
      #
      # @return [Object, nil] Property value if found
      #
      def method_missing(method_name, *args)
        if additional_properties.key?(method_name)
          additional_properties[method_name]
        else
          super
        end
      end

      # Indicate whether the object responds to the given method
      #
      # @param method_name [Symbol] Method name
      # @param include_private [Boolean] Whether to include private methods
      #
      # @return [Boolean] Whether the object responds to the method
      #
      def respond_to_missing?(method_name, include_private = false)
        additional_properties.key?(method_name) || super
      end

      # Convert the struct to a hash, including additional properties
      #
      # @return [Hash] All properties as a hash
      #
      def to_h
        super.merge(additional_properties)
      end

      # Override the camelize method to handle additional properties correctly
      #
      # @param value [Object] The value to convert
      #
      # @return [Object] The value with camelized keys if applicable
      #
      def camelize(value)
        case value
        when Hash
          value.to_h do |key, v|
            [INFLECTOR.camelize_lower(key.to_s).to_sym, camelize(v)]
          end
        when Array
          value.map { |item| camelize(item) }
        else
          value
        end
      end

      # Class methods added to the class that includes AdditionalProperties
      module ClassMethods
        # Override the new method to handle additional properties
        #
        # @param hash [Hash, nil] Input hash including both schema and additional properties
        #
        # @return [Object] New instance with additional properties preserved
        #
        def new(hash = nil)
          hash = {} if hash.nil?

          # Convert all keys to symbols
          input = hash.transform_keys(&:to_sym)

          # Get schema keys
          schema_keys = schema.keys.map(&:name)

          # Split input into schema data and additional properties
          schema_data = {}
          additional_props = {}

          input.each do |key, value|
            snake_key = INFLECTOR.underscore(key.to_s).to_sym

            if schema_keys.include?(snake_key)
              schema_data[snake_key] = value
            elsif schema_keys.include?(key)
              schema_data[key] = value
            else
              # Store additional properties with snake_case keys
              additional_props[snake_key] = value
            end
          end

          # Create instance using schema data
          instance = super(schema_data)

          # Attach additional properties
          instance.instance_variable_set(:@additional_properties, additional_props)

          instance
        end
      end
    end
  end
end
