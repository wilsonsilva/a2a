# frozen_string_literal: true

module A2A
  # Utility functions for the A2A protocol
  module Utils
    # Get the current timestamp in ISO 8601 format
    # @return [String] Current timestamp
    def self.current_timestamp
      Time.now.iso8601
    end

    # Check if a value is a plain Hash (not an Array or nil)
    # @param value [Object] The value to check
    # @return [Boolean] True if the value is a plain Hash
    def self.hash?(value)
      value.is_a?(Hash)
    end

    # Check if an update is a task status update (has 'state', no 'parts')
    # @param update [Hash] The update to check
    # @return [Boolean] True if it's a task status update
    def self.task_status_update?(update)
      hash?(update) && update.key?('state') && !update.key?('parts')
    end

    # Check if an update is an artifact update (has 'parts')
    # @param update [Hash] The update to check
    # @return [Boolean] True if it's an artifact update
    def self.artifact_update?(update)
      hash?(update) && update.key?('parts')
    end

    # Parse a JSON string safely
    # @param json_string [String] The JSON string to parse
    # @return [Hash, Array, nil] The parsed object or nil if parsing failed
    def self.parse_json(json_string)
      JSON.parse(json_string)
    rescue JSON::ParserError
      nil
    end

    # Check if a string appears to be a valid UUID
    # @param str [String] The string to check
    # @return [Boolean] True if the string appears to be a valid UUID
    def self.valid_uuid?(str)
      uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
      !!(str =~ uuid_regex)
    end

    # Generate a simple request ID
    # @return [String] A unique request ID
    def self.generate_request_id
      SecureRandom.uuid
    end

    # Create a deep copy of an object
    # @param obj [Object] The object to copy
    # @return [Object] A deep copy of the object
    def self.deep_copy(obj)
      Marshal.load(Marshal.dump(obj))
    rescue TypeError
      # Fall back to JSON serialization for objects that can't be marshalled
      begin
        JSON.parse(JSON.generate(obj))
      rescue
        # If all else fails, return the original object
        obj
      end
    end

    # Convert keys in a hash from camelCase to snake_case recursively
    # @param obj [Hash, Array, Object] The object to convert
    # @return [Hash, Array, Object] The object with converted keys
    def self.snake_case_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), result|
          new_key = k.to_s.gsub(/([A-Z])/) { |m| "_#{m.downcase}" }
          result[new_key] = snake_case_keys(v)
        end
      when Array
        obj.map { |item| snake_case_keys(item) }
      else
        obj
      end
    end

    # Convert keys in a hash from snake_case to camelCase recursively
    # @param obj [Hash, Array, Object] The object to convert
    # @return [Hash, Array, Object] The object with converted keys
    def self.camel_case_keys(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(k, v), result|
          next if k.nil?
          new_key = k.to_s.gsub(/_([a-z])/) { |_| $1.upcase }
          result[new_key] = camel_case_keys(v)
        end
      when Array
        obj.map { |item| camel_case_keys(item) }
      else
        obj
      end
    end
  end
end
