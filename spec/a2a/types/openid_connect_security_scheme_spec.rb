# frozen_string_literal: true

RSpec.describe A2A::OpenIdConnectSecurityScheme do
  describe '.new' do
    context 'when given attributes with snake case keys' do
      # Attributes defined in the factory are snake case
      let(:security_scheme_attributes) { attributes_for(:openid_connect_security_scheme) }

      it 'initializes an OpenID Connect security scheme' do
        security_scheme = described_class.new(security_scheme_attributes)

        expect(security_scheme).to be_a(described_class)
      end
    end

    context 'when given attributes with camel case keys' do
      let(:security_scheme_attributes) do
        attributes_for(:openid_connect_security_scheme).merge(
          openIdConnectUrl: 'https://auth.example.com/.well-known/openid-configuration'
        )
      end

      it 'initializes an OpenID Connect security scheme' do
        security_scheme = described_class.new(security_scheme_attributes)

        expect(security_scheme).to be_a(described_class)
      end
    end

    context 'when the required attributes are missing' do
      let(:security_scheme_attributes) do
        {
          type: 'openIdConnect'
        }
      end

      it 'raises an error' do
        expect { described_class.new(security_scheme_attributes) }.to raise_error(Dry::Struct::Error)
      end
    end

    context 'when type is incorrect' do
      let(:security_scheme_attributes) do
        {
          type: 'oauth2',
          open_id_connect_url: 'https://auth.example.com/.well-known/openid-configuration'
        }
      end

      it 'raises an error' do
        expect { described_class.new(security_scheme_attributes) }.to raise_error(Dry::Struct::Error)
      end
    end
  end

  describe '#to_h' do
    let(:security_scheme) { build(:openid_connect_security_scheme, :google_oidc) }

    it 'converts the security scheme to a hash' do
      expect(security_scheme.to_h).to eq(
        type: 'openIdConnect',
        open_id_connect_url: 'https://accounts.google.com/.well-known/openid-configuration',
        description: 'Google OpenID Connect authentication'
      )
    end
  end

  describe '#to_json' do
    context 'when camel_case is true (default)' do
      let(:security_scheme) { build(:openid_connect_security_scheme, :google_oidc) }

      it 'returns a JSON string with camel case keys' do
        expect(security_scheme.to_json).to match_json(<<~JSON)
          {
            "type": "openIdConnect",
            "openIdConnectUrl": "https://accounts.google.com/.well-known/openid-configuration",
            "description": "Google OpenID Connect authentication"
          }
        JSON
      end
    end

    context 'when camel_case is false' do
      let(:security_scheme) { build(:openid_connect_security_scheme, :custom_oidc) }

      it 'returns a JSON string with snake case keys' do
        expect(security_scheme.to_json(camel_case: false)).to match_json(<<~JSON)
          {
            "type": "openIdConnect",
            "open_id_connect_url": "https://auth.example.com/.well-known/openid-configuration",
            "description": "Custom OpenID Connect provider"
          }
        JSON
      end
    end
  end

  describe '.from_json' do
    let(:json_string) do
      <<~JSON
        {
          "type": "openIdConnect",
          "openIdConnectUrl": "https://accounts.google.com/.well-known/openid-configuration",
          "description": "Google OpenID Connect authentication"
        }
      JSON
    end

    it 'initializes an OpenID Connect security scheme' do
      security_scheme = described_class.from_json(json_string)

      expect(security_scheme).to be_a(described_class)
    end

    it 'parses type' do
      security_scheme = described_class.from_json(json_string)

      expect(security_scheme.type).to eq('openIdConnect')
    end

    it 'parses open_id_connect_url' do
      security_scheme = described_class.from_json(json_string)

      expect(security_scheme.open_id_connect_url).to eq('https://accounts.google.com/.well-known/openid-configuration')
    end

    it 'parses description' do
      security_scheme = described_class.from_json(json_string)

      expect(security_scheme.description).to eq('Google OpenID Connect authentication')
    end
  end
end
