require 'http'
require 'delegate'
require 'logger'

module A2A
  class HTTPClient < SimpleDelegator
    # Initialize the HTTP client with optional debugging
    #
    # @param debug [Boolean] Whether to log HTTP requests and responses
    # @param logger [Logger] Custom logger instance (defaults to STDOUT)
    #
    def initialize(debug: false, logger: nil)
      @logger = logger || Logger.new($stdout, level: Logger::INFO)
      @http = HTTP

      # Set up logging if debug mode is enabled
      # @http = @http.use(logging: { logger: @logger }) if debug

      # Use SimpleDelegator to delegate all methods to @http
      super(@http)
    end
  end
end
