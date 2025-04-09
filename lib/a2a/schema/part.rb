module A2A
  module Schema
    # Base class for all part types
    class Part < SchemaObject
      attr_accessor :metadata

      def initialize(metadata: nil)
        @metadata = metadata
      end

      REQUIRED_FIELDS = [].freeze
    end
  end
end
