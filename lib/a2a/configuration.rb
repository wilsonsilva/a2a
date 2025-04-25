# frozen_string_literal: true

require 'singleton'

module A2A
  # Configuration class for managing global A2A configuration
  class Configuration
    include Singleton

    # Create a new Configuration instance
    def initialize
      @options = {
        # Default task persistence
        persistence: :memory,

        # Default timeout values
        task_timeout: 300, # 5 minutes
        network_timeout: 60, # 1 minute

        # Default authentication
        authentication_enabled: false,
        authentication_provider: nil,

        # Storage options
        storage_path: nil,

        # Logging
        log_level: :info,
        logger: nil
      }

      # Advanced options
      @advanced_options = {
        max_concurrent_tasks: 10,
        enable_push_notifications: true,
        enable_streaming: true,
        enable_metrics: false,
        backpressure_strategy: :drop_old
      }
    end

    # Get a configuration option
    # @param key [Symbol] The option key
    # @return The option value
    def [](key)
      @options[key]
    end

    # Set a configuration option
    # @param key [Symbol] The option key
    # @param value The option value
    def []=(key, value)
      @options[key] = value
    end

    # Get an advanced configuration option
    # @param key [Symbol] The option key
    # @return The option value
    def advanced(key)
      @advanced_options[key]
    end

    # Set an advanced configuration option
    # @param key [Symbol] The option key
    # @param value The option value
    def set_advanced(key, value)
      @advanced_options[key] = value
    end

    # Configure multiple options at once
    # @param options [Hash] The options to set
    # @yield [config] Yields the configuration instance for block-style configuration
    # @return [self] Returns self for method chaining
    def configure(options = {})
      options.each { |key, value| self[key] = value }
      yield self if block_given?
      self
    end

    # Configure advanced options
    # @param options [Hash] The advanced options to set
    # @yield [config] Yields the configuration instance for block-style configuration
    # @return [self] Returns self for method chaining
    def configure_advanced(options = {})
      options.each { |key, value| set_advanced(key, value) }
      yield @advanced_options if block_given?
      self
    end

    # Create a task storage adapter based on the current configuration
    # @return [#get, #set, #delete] A task storage adapter
    def create_task_storage
      case @options[:persistence]
      when :memory
        InMemoryTaskStorage.new
      when :file
        path = @options[:storage_path] || File.join(Dir.pwd, 'a2a_tasks')
        FileTaskStorage.new(path)
      when :redis
        require 'redis'
        redis = Redis.new(url: @options[:redis_url])
        RedisTaskStorage.new(redis)
      else
        if @options[:custom_storage]
          @options[:custom_storage]
        else
          InMemoryTaskStorage.new
        end
      end
    end

    # Get or create a logger based on the current configuration
    # @return [Logger] A logger instance
    def logger
      return @options[:logger] if @options[:logger]

      require 'logger'
      Logger.new($stdout).tap do |logger|
        logger.level = Logger.const_get(@options[:log_level].to_s.upcase)
      end
    end
  end

  # File-based task storage implementation
  # @private
  class FileTaskStorage
    def initialize(directory)
      require 'fileutils'
      @directory = directory
      FileUtils.mkdir_p(@directory)
    end

    def get(task_id)
      file_path = file_path_for(task_id)
      return nil unless File.exist?(file_path)

      data = File.read(file_path)
      JSON.parse(data, symbolize_names: true)
    end

    def set(task_id, task)
      file_path = file_path_for(task_id)
      File.write(file_path, task.to_json)
    end

    def delete(task_id)
      file_path = file_path_for(task_id)
      File.delete(file_path) if File.exist?(file_path)
    end

    private

    def file_path_for(task_id)
      File.join(@directory, "#{task_id}.json")
    end
  end

  # Redis-based task storage implementation
  # @private
  class RedisTaskStorage
    def initialize(redis)
      @redis = redis
      @prefix = 'a2a:task:'
    end

    def get(task_id)
      key = "#{@prefix}#{task_id}"
      data = @redis.get(key)
      return nil if data.nil?

      JSON.parse(data, symbolize_names: true)
    end

    def set(task_id, task)
      key = "#{@prefix}#{task_id}"
      @redis.set(key, task.to_json)
    end

    def delete(task_id)
      key = "#{@prefix}#{task_id}"
      @redis.del(key)
    end
  end

  # Configure the A2A gem
  # @param options [Hash] The options to set
  # @yield [config] Yields the configuration instance for block-style configuration
  # @return [Configuration] The configuration instance
  def self.configure(options = {})
    config = Configuration.instance
    config.configure(options)
    yield config if block_given?
    config
  end

  # Access the current configuration
  # @return [Configuration] The current configuration
  def self.config
    Configuration.instance
  end
end
