# frozen_string_literal: true

require_relative 'rack_transport'

module A2A
  module Transports
    # Authenticated Rack transport for A2A
    # Extends RackTransport with token-based authentication
    class AuthenticatedRackTransport < RackTransport
      def initialize(app, server, options = {})
        super

        @auth_token = options[:auth_token]
        @auth_header_name = options[:auth_header_name] || 'Authorization'
        @auth_exempt_paths = options[:auth_exempt_paths] || ["/.well-known/agent.json"]
        @auth_enabled = !@auth_token.nil?
      end

      # Override call method to add authentication
      def call(env)
        request = Rack::Request.new(env)

        if auth_enabled? && !exempt_from_auth?(request.path)
          auth_header = request.env["HTTP_#{@auth_header_name.upcase.gsub('-', '_')}"]
          token = auth_header&.gsub('Bearer ', '')

          return unauthorized_response(request) unless valid_token?(token)
        end

        super
      end

      private

      # Check if authentication is enabled
      def auth_enabled?
        @auth_enabled
      end

      # Check if a path is exempt from authentication
      def exempt_from_auth?(path)
        full_path = path
        # Make sure path starts with prefix for comparison
        full_path = "#{@path_prefix}#{path}" if !path.start_with?(@path_prefix)

        @auth_exempt_paths.any? { |exempt_path| full_path.include?(exempt_path) }
      end

      # Validate a token
      def valid_token?(token)
        token == @auth_token
      end

      # Return an unauthorized response
      def unauthorized_response(request)
        body = JSON.generate(
          {
            jsonrpc: '2.0',
            error: {
              code: -32000,
              message: 'Unauthorized: Invalid or missing authentication token'
            },
            id: extract_request_id(request)
          }
        )

        [401, { 'Content-Type' => 'application/json' }, [body]]
      end

      # Extract request ID from the request
      def extract_request_id(request)
        return nil unless request.post?

        begin
          body = request.body.read
          request.body.rewind
          JSON.parse(body)['id']
        rescue StandardError
          nil
        end
      end
    end
  end
end
