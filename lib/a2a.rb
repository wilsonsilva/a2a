# frozen_string_literal: true

require 'dry/inflector'
require 'zeitwerk'
require 'jsonrpc'
require 'a2a/rails/railtie' if defined?(Rails)

# Encapsulates all the gem's logic
module A2A
  # @!visibility private
  # @return [Dry::Inflector] The inflector instance used for camelizing keys
  INFLECTOR = Dry::Inflector.new
end

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'a2a' => 'A2A',
  'api_key_security_scheme' => 'APIKeySecurityScheme',
  'authorization_code_oauth_flow' => 'AuthorizationCodeOAuthFlow',
  'client_credentials_oauth_flow' => 'ClientCredentialsOAuthFlow',
  'http_auth_security_scheme' => 'HTTPAuthSecurityScheme',
  'implicit_oauth_flow' => 'ImplicitOAuthFlow',
  'json_deserialization' => 'JSONDeserialization',
  'jsonrpc_helpers' => 'JSONRPCHelpers',
  'mutual_tls_security_scheme' => 'MutualTLSSecurityScheme',
  'oauth2_security_scheme' => 'OAuth2SecurityScheme',
  'oauth_flows' => 'OAuthFlows',
  'openid_connect_security_scheme' => 'OpenIdConnectSecurityScheme',
  'password_oauth_flow' => 'PasswordOAuthFlow',
  'uri' => 'URI'
)
loader.collapse("#{__dir__}/a2a/types")
loader.ignore("#{__dir__}/a2a/rails/railtie.rb")
loader.enable_reloading
loader.setup
loader.eager_load
