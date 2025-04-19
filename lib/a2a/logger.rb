# frozen_string_literal: true

require 'logger'

module A2A
  # Custom logger for A2A
  class Logger < ::Logger
    def initialize(transport: :stdio)
      @client_initialized = false
      @transport = transport

      # Don't log to stdout if we're using the stdio transport to avoid conflicts
      super($stdout) unless stdio_transport?
    end

    attr_accessor :transport, :client_initialized
    alias client_initialized? client_initialized

    # Check if using STDIO transport
    def stdio_transport?
      transport == :stdio
    end

    # Override the add method to customize logging behavior
    def add(severity, message = nil, progname = nil, &block)
      return if stdio_transport? # Don't log to stdout when using stdio transport

      # Standard logger behavior otherwise
      super
    end

    # Check if using Rack transport
    def rack_transport?
      transport == :rack
    end
  end
end
