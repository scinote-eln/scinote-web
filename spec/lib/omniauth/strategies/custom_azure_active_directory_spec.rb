# frozen_string_literal: true

require 'rails_helper'

describe OmniAuth::Strategies::CustomAzureActiveDirectory do
  let(:conf_url) { 'https://login.example.com/tenant/.well-known/openid-configuration' }
  let(:strategy) do
    described_class.new(
      ->(_env) { [200, {}, ['ok']] }, client_id: 'client-id', client_secret: 'client-secret', conf_url: conf_url
    )
  end
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:app_conf) do
    {
      'authorization_endpoint' => 'https://login.example.com/tenant/oauth2/v2.0/authorize',
      'token_endpoint' => 'https://login.example.com/tenant/oauth2/v2.0/token'
    }
  end

  before do
    allow(Rails).to receive(:cache).and_return(cache)
    strategy.instance_variable_set(:@env, Rack::MockRequest.env_for('/auth/customazureactivedirectory'))
  end

  it 'has its own provider name and extends the Azure AD v2 strategy' do
    expect(strategy.options.name).to eq 'customazureactivedirectory'
    expect(described_class.superclass).to eq OmniAuth::Strategies::AzureActivedirectoryV2
  end

  it 'registers the camelization for the provider name' do
    expect(OmniAuth::Utils.camelize('custom_azure_activedirectory')).to eq 'CustomAzureActiveDirectory'
  end

  describe '#client' do
    it 'takes the authorize and token urls from the remote configuration and caches it' do
      stub = stub_request(:get, conf_url).to_return(status: 200, body: app_conf.to_json)

      client = strategy.client
      expect(client.options[:authorize_url]).to eq app_conf['authorization_endpoint']
      expect(client.options[:token_url]).to eq app_conf['token_endpoint']
      expect(cache.read('ad_app_conf_client-id')).to eq app_conf

      strategy.client
      expect(stub).to have_been_requested.once
    end

    it 'logs and keeps the defaults when the configuration cannot be loaded' do
      stub_request(:get, conf_url).to_return(status: 200, body: 'not json')
      allow(Rails.logger).to receive(:error)

      client = strategy.client
      expect(Rails.logger).to have_received(:error).with(/Failed to load OAuth2 configuration/)
      expect(client).to be_a(OAuth2::Client)
      expect(client.options[:authorize_url]).not_to eq app_conf['authorization_endpoint']
    end
  end

  describe '#raw_info' do
    def jwt(payload)
      JWT.encode(payload, nil, 'none')
    end

    def stub_tokens(access:, id:)
      token = instance_double(OAuth2::AccessToken, token: access, params: { 'id_token' => id })
      allow(strategy).to receive(:access_token).and_return(token)
    end

    it 'merges access token claims with id token claims, id token winning' do
      stub_tokens(access: jwt('sub' => 'access-sub', 'scp' => 'User.Read'), id: jwt('sub' => 'id-sub', 'email' => 'a@b.c'))
      expect(strategy.raw_info).to eq('sub' => 'id-sub', 'scp' => 'User.Read', 'email' => 'a@b.c')
    end

    it 'falls back to the other token when one cannot be decoded' do
      stub_tokens(access: 'garbage', id: jwt('email' => 'a@b.c'))
      expect(strategy.raw_info).to eq('email' => 'a@b.c')
    end

    it 'is empty when neither token can be decoded' do
      stub_tokens(access: 'garbage', id: 'garbage')
      expect(strategy.raw_info).to eq({})
    end

    it 'memoizes the result' do
      stub_tokens(access: jwt('a' => 1), id: jwt('b' => 2))
      first = strategy.raw_info
      expect(strategy).not_to receive(:access_token)
      expect(strategy.raw_info).to equal(first)
    end

    it 'feeds the auth hash fields' do
      stub_tokens(access: jwt('x' => 1), id: jwt('oid' => 'uid-1', 'email' => 'a@b.c', 'name' => 'Ann'))
      expect(strategy.uid).to eq 'uid-1'
      expect(strategy.info).to include(email: 'a@b.c', name: 'Ann')
    end
  end
end
