# frozen_string_literal: true

require 'spec_helper'
require 'kong/client'

RSpec.describe Kong::Client do
  let(:client) { described_class.new url: url }
  let(:url) { 'http://kong:8000/admin-api' }

  it { expect(client.consumers).to be_a(Kong::Clients::Consumers) }
  it { expect(client.apis).to be_a(Kong::Clients::APIs) }
  it { expect(client.plugins).to be_a(Kong::Clients::Plugin) }
end
