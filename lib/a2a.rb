# frozen_string_literal: true

require 'json'
require 'time'
require 'securerandom'
require 'base64'
require 'fileutils'
require 'uri'
require 'rack'

# Core components
require_relative 'a2a/version'
require_relative 'a2a/schema'
require_relative 'a2a/errors'
require_relative 'a2a/utils'

# Storage implementations
require_relative 'a2a/store/base'
require_relative 'a2a/store/memory'
require_relative 'a2a/store/file'

# Client and server implementations
require_relative 'a2a/client'
require_relative 'a2a/server'

# A2A namespace module
module A2A
  class << self
    # Generate a new UUID for task IDs, etc.
    # @return [String] A new UUID
    def generate_uuid
      SecureRandom.uuid
    end

    # Get the current timestamp in ISO 8601 format
    # @return [String] Current time in ISO 8601 format
    def current_timestamp
      Time.now.iso8601
    end
  end
end
