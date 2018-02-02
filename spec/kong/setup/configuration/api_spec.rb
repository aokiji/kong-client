# frozen_string_literal: true

require 'spec_helper'
require 'kong/setup/configuration/api'

RSpec.describe Kong::Setup::Configuration::API do
  subject(:config) { described_class.new(config_hash) }

  describe '#uris' do
    let(:config_hash) { { 'name' => 'api1', 'version' => 'v1', 'endpoints' => %w[e1 e2] } }

    it { expect(config.uris).to eq('/v1/e1,/v1/e2') }
  end
end
