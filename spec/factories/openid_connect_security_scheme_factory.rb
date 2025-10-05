# frozen_string_literal: true

FactoryBot.define do
  factory :openid_connect_security_scheme, class: 'A2A::OpenIdConnectSecurityScheme' do
    initialize_with { new(**attributes) }

    trait :google_oidc do
      type { 'openIdConnect' }
      open_id_connect_url { 'https://accounts.google.com/.well-known/openid-configuration' }
      description { 'Google OpenID Connect authentication' }
    end

    trait :custom_oidc do
      type { 'openIdConnect' }
      open_id_connect_url { 'https://auth.example.com/.well-known/openid-configuration' }
      description { 'Custom OpenID Connect provider' }
    end

    google_oidc
  end
end
