# frozen_string_literal: true

require 'spec_helper'
require 'kong/setup'

RSpec.describe Kong::Setup::Runner do
  subject(:runner) { described_class.new(config) }

  let(:config) { Kong::Setup::Configuration.from_file('spec/kong/setup/config.yml', :development) }
  let(:client) { instance_spy Kong::Client }
  let(:consumers_client) { instance_spy Kong::Clients::Consumers }
  let(:apis_client) { instance_spy Kong::Clients::APIs }
  let(:basic_auth_client) { instance_spy Kong::Clients::Plugins::BasicAuth }
  let(:plugins_client) { instance_spy Kong::Clients::Plugin }
  let(:anonymous_id) { SecureRandom.uuid }
  let(:anonymous) { Kong::Resources::Consumer.new(id: anonymous_id, username: 'anonymous') }

  before do
    runner.instance_variable_set(:@client, client)
    allow(client).to receive(:consumers).and_return(consumers_client)
    allow(client).to receive(:apis).and_return(apis_client)
    allow(consumers_client).to receive(:basic_auth).and_return(basic_auth_client)
    allow(consumers_client).to receive(:find_by).with('username' => 'anonymous')
                                                .and_return(anonymous)
    allow(client).to receive(:plugins).and_return(plugins_client)
  end

  describe '#apply' do
    before { runner.apply }

    it do
      expect(consumers_client).to have_received(:find_or_create_by).with('custom_id' => 1)
    end
    it do
      expect(basic_auth_client).to have_received(:find_or_create_by)
        .with('username' => 'cons', 'password' => 'umer')
    end
    it do
      expect(apis_client).to have_received(:find_or_create_by)
        .with('name' => 'api1.v1', 'strip_uri' => false, 'upstream_url' => 'http://app1:3000',
              'uris' => '/v1/admins,/v1/roles')
    end
    it do
      expect(apis_client).to have_received(:find_or_create_by)
        .with('name' => 'api2.v1', 'strip_uri' => false, 'upstream_url' => 'http://app2:3000',
              'uris' => '/v1/auth')
    end
    it do
      expect(apis_client).to have_received(:update)
        .with(any_args, 'name' => 'api1.v1', 'strip_uri' => false,
                        'uris' => '/v1/admins,/v1/roles', 'upstream_url' => 'http://app1:3000')
    end
    it do
      expect(apis_client).to have_received(:update)
        .with(any_args, 'name' => 'api2.v1', 'strip_uri' => false,
                        'upstream_url' => 'http://app2:3000', 'uris' => '/v1/auth')
    end
    it do
      expect(plugins_client).to have_received(:find_or_create_by)
        .with('name' => 'basic-auth', 'config' => { 'anonymous' => anonymous_id })
    end
    it do
      expect(plugins_client).to have_received(:find_or_create_by)
        .with('name' => 'jwt', 'config' => { 'claims_to_verify' => 'exp' })
    end
  end
end
