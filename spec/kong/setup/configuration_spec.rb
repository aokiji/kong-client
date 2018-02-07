# frozen_string_literal: true

require 'spec_helper'
require 'kong/setup/configuration'

RSpec.describe Kong::Setup::Configuration do
  subject(:config) { described_class.new(config_hash) }

  describe '#initialize' do
    let(:config_hash) { {} }

    it { expect(config.apis).to be_a(Array).and be_empty }
    it { expect(config.consumers).to be_a(Array).and be_empty }
    it { expect(config.plugins).to be_a(Array).and be_empty }
    it { expect(config.admin_api).to be_a(Hash).and be_empty }
  end

  describe '#admin_api' do
    let(:config_hash) { { 'admin-api' => { 'url' => url, 'headers' => headers } } }
    let(:url) { 'http://kong:8000/admin-api' }
    let(:apikey) { SecureRandom.hex(16) }
    let(:headers) { { 'apikey' => apikey } }

    it { expect(config.admin_api['url']).to eq(url) }
    it { expect(config.admin_api['headers']).to eq(headers) }
  end

  describe '#apis' do
    let(:config_hash) { { 'apis' => { 'api1' => api1_config, 'api2' => api2_config } } }
    let(:api1_config) { { 'version' => 'v1', 'endpoints' => %w[e1 e2] } }
    let(:api2_config) { { 'version' => 'v2', 'upstream_url' => 'up2' } }
    let(:apis) { config.apis }

    it do
      expect(apis[0]).to be_a(Kong::Setup::Configuration::API)
        .and have_attributes(name: 'api1', version: 'v1', endpoints: %w[e1 e2])
    end
    it do
      expect(apis[1]).to be_a(Kong::Setup::Configuration::API)
        .and have_attributes(name: 'api2', version: 'v2', upstream_url: 'up2')
    end
  end

  describe '#plugins' do
    let(:config_hash) { { 'plugins' => { 'basic-auth' => basic_auth, 'jwt' => jwt_config } } }
    let(:basic_auth) { {} }
    let(:jwt_config) { { 'config' => { 'claims_to_verify' => 'exp' } } }

    it { expect(config.plugins[0]).to have_attributes(name: 'basic-auth') }
    it { expect(config.plugins[1]).to have_attributes(name: 'jwt', config: jwt_config['config']) }
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
    describe 'one configuration instance' do
      subject(:config) { described_class.from_file('spec/kong/setup/config.yml', :development) }

      let(:api1) { config.apis[0] }
      let(:api2) { config.apis[1] }
      let(:consumers) { config.consumers }
      let(:basic_auth) { { 'username' => 'cons', 'password' => 'umer' } }

      it { expect(config.admin_api).to eq('url' => 'http://kong:8001') }
      it do
        expect(api1).to have_attributes(name: 'api1.v1', version: 'v1', strip_uri: false,
                                        upstream_url: 'http://app1:3000',
                                        endpoints: %w[admins roles])
      end
      it do
        expect(api2).to have_attributes(name: 'api2.v1', version: 'v1', strip_uri: false,
                                        upstream_url: 'http://app2:3000', endpoints: %w[auth])
      end
      it { expect(config.plugins[0]).to have_attributes(name: 'basic-auth') }
      it do
        expect(config.plugins[1])
          .to have_attributes(name: 'jwt', config: { 'claims_to_verify' => 'exp' })
      end
      it do
        expect(consumers).to match_array([have_attributes(custom_id: 1, basic_auth: basic_auth),
                                          have_attributes(username: 'anonymous')])
      end
    end

    describe 'multiple configuration instance' do
      subject(:config) { described_class.from_file('spec/kong/setup/config2.yml', :development) }

      let(:api1) { config[1].apis[0] }
      let(:api2) { config[0].apis[0] }
      let(:basic_auth) { { 'username' => 'cons', 'password' => 'umer' } }

      it { is_expected.to be_a(Array).and have_attributes(length: 2)  }

      it do
        expect(config[0].admin_api)
          .to eq('url' => 'http://kong:8001', 'headers' => { 'apikey' => 'apikey' })
      end
      it { expect(config[1].admin_api).to eq('url' => 'http://kong:8001/admin-api') }
      it do
        expect(api1).to have_attributes(name: 'api1.v1', version: 'v1', strip_uri: false,
                                        upstream_url: 'http://app1',
                                        endpoints: %w[admins roles])
      end
      it do
        expect(api2).to have_attributes(name: 'api2.v1', version: 'v1', strip_uri: false,
                                        upstream_url: 'http://app2', endpoints: %w[auth])
      end
      it { expect(config[0].plugins[0]).to have_attributes(name: 'basic-auth') }
      it { expect(config[1].plugins[0]).to have_attributes(name: 'basic-auth') }
    end
  end
end
