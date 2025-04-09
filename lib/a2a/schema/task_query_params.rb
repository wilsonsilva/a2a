# frozen_string_literal: true

module A2A
  module Schema
    # Task query parameters (get, subscribe, resubscribe)
    class TaskQueryParams < TaskIdParams
      attr_accessor :history_length

      # @param id [String] Task ID
      # @param history_length [Integer, nil] Optional history length
      # @param metadata [Hash, nil] Optional metadata
      def initialize(id:, history_length: nil, metadata: nil)
        super(id: id, metadata: metadata)
        @history_length = history_length
      end

      REQUIRED_FIELDS = [:id].freeze
    end
  end
end