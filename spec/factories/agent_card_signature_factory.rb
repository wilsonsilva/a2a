# frozen_string_literal: true

FactoryBot.define do
  factory :agent_card_signature, class: 'A2A::AgentCardSignature' do
    initialize_with { new(**attributes) }

    trait :example_signature do
      protected do
        'eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMSIsImprdSI6Imh0dHBzOi8vZXhh' \
          'bXBsZS5jb20vYWdlbnQvandrcy5qc29uIn0'
      end
      signature { 'QFdkNLNszlGj3z3u0YQGt_T9LixY3qtdQpZmsTdDHDe3fXV9y9-B3m2-XgCpzuhiLt8E0tV6HXoZKHv4GtHgKQ' }
      header { nil }
    end

    trait :with_header do
      protected do
        'eyJhbGciOiJFUzI1NiIsInR5cCI6IkpPU0UiLCJraWQiOiJrZXktMiJ9'
      end
      signature { 'abc123xyz789signature' }
      header { { 'kid' => 'key-2', 'custom' => 'value' } }
    end

    example_signature
  end
end
