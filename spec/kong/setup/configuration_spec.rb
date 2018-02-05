# frozen_string_literal: true

require 'spec_helper'
require 'kong/setup/configuration'

RSpec.describe Kong::Setup::Configuration do
  subject(:config) { described_class.new(config_hash) }

  describe '#admin_api' do
    let(:config_hash) { { 'admin-api' => { url: url, headers: headers } } }
    let(:url) { 'http://kong:8000/admin-api' }
    let(:apikey) { SecureRandom.hex(16) }
    let(:headers) { { 'apikey' => apikey } }

    it { expect(config.admin_api.url).to eq(url) }
    it { expect(config.admin_api.headers).to eq(headers) }
  end

  describe '#apis' do
    let(:config_hash) { { 'apis' => { 'api1' => api1_config, 'api2' => api2_config } } }
    let(:api1_config) { { 'name' => 'api1', 'version' => 'v1', 'endpoints' => %w[e1 e2] } }
    let(:api2_config) { { 'name' => 'api2', 'version' => 'v2', 'upstream_url' => 'up2' } }
    let(:apis) { config.apis }

    it do
      expect(apis.api1).to be_a(Kong::Setup::Configuration::API)
        .and have_attributes(name: 'api1', version: 'v1', endpoints: %w[e1 e2])
    end
    it do
      expect(apis.api2).to be_a(Kong::Setup::Configuration::API)
        .and have_attributes(name: 'api2', version: 'v2', upstream_url: 'up2')
    end
  end

  describe '#plugins' do
    let(:config_hash) { { 'plugins' => { 'basic-auth' => basic_auth, 'jwt' => jwt_config } } }
    let(:basic_auth) { {} }
    let(:jwt_config) { { 'config' => { 'claims_to_verify' => 'exp' } } }

    it { expect(config.plugins.basic_auth).to have_attributes(name: 'basic-auth') }
    it { expect(config.plugins.jwt).to have_attributes(name: 'jwt', config: jwt_config['config']) }
  end

  describe '#consumers' do
    let(:config_hash) { { 'consumers' => [{ username: username, custom_id: id }] } }
    let(:username) { SecureRandom.hex(16) }
    let(:id) { SecureRandom.hex(16) }
    let(:consumers) { config.consumers }

    it do
      expect(consumers).to match_array(be_a(Kong::Setup::Configuration::Consumer)
        .and(have_attributes(username: username, custom_id: id)))
    end
  end

  describe ':from_file' do
    subject(:config) { described_class.from_file('spec/kong/setup/config.yml', :development) }

    let(:api1) { config.apis.api1 }
    let(:api2) { config.apis.api2 }
    let(:consumers) { config.consumers }
    let(:basic_auth) { { 'username' => 'cons', 'password' => 'umer' } }

    it { expect(config.admin_api).to have_attributes(url: 'http://kong:8001') }
    it do
      expect(api1).to have_attributes(name: 'api1.v1', version: 'v1', strip_uri: false,
                                      upstream_url: 'http://app1:3000', endpoints: %w[admins roles])
    end
    it do
      expect(api2).to have_attributes(name: 'api2.v1', version: 'v1', strip_uri: false,
                                      upstream_url: 'http://app2:3000', endpoints: %w[auth])
    end
    it { expect(config.plugins.basic_auth).to have_attributes(name: 'basic-auth') }
    it do
      expect(config.plugins.jwt)
        .to have_attributes(name: 'jwt', config: { 'claims_to_verify' => 'exp' })
    end
    it { expect(consumers).to match_array(have_attributes(custom_id: 1, basic_auth: basic_auth)) }
  end
end
