# frozen_string_literal: true

module A2A
  # Authentication information, potentially including additional properties beyond the standard ones.
  # (Note: Schema allows additional properties).
  class AuthenticationInfo < AgentAuthentication
    include Extensions::AdditionalProperties
  end
end
