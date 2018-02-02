# frozen_string_literal: true

require 'spec_helper'
require 'kong/connection'
require 'kong/clients/apis'

RSpec.describe Kong::Clients::APIs do
  let(:api) { Kong::Resources::API.new(id: api_id, name: name, upstream_url: upstream) }
  let(:client) { described_class.new(connection) }
  let(:connection) { instance_double(Kong::Connection) }
  let(:apis_path) { 'apis' }
  let(:api_path) { "apis/#{api_id}" }
  let(:api_id) { SecureRandom.hex(16) }
  let(:name) { 'test.api' }
  let(:upstream) { 'http://upstream/here' }

  describe '#create' do
    shared_examples 'create api' do
      before do
        allow(connection).to receive(:create)
          .with(apis_path, 'name' => name, 'upstream_url' => upstream)
          .and_return(id: api_id, name: name, upstream_url: upstream)
        create_api
      end

      it { is_expected.to eq(api) }
      it { expect(connection).to have_received(:create) }
    end

    context 'with no block' do
      subject(:create_api) { client.create(name: name, upstream_url: upstream) }

      it_behaves_like 'create api'
    end

    context 'with block' do
      subject(:create_api) do
        client.create do |api|
          api.name = name
          api.upstream_url = upstream
        end
      end

      it_behaves_like 'create api'
    end
  end

  describe '#update' do
    subject(:update_api) { client.update(api, upstream_url: upstream) }

    before do
      allow(connection).to receive(:update)
        .with(api_path, upstream_url: upstream)
        .and_return(id: api_id, name: name, upstream_url: upstream)
      update_api
    end

    it { is_expected.to eq(api) }
    it { expect(connection).to have_received(:update) }
  end

  describe '#delete' do
    subject(:delete_api) { client.delete(api) }

    before do
      allow(connection).to receive(:delete).with(api_path).and_return(true)
      delete_api
    end

    it { expect(connection).to have_received(:delete).with(api_path) }
  end

  describe '#all' do
    subject { client.all }

    let(:api1_attrs) { { 'id' => 1, 'name' => 'name1', 'upstream_url' => 'up1' } }
    let(:api2_attrs) { { 'id' => 2, 'name' => 'name2', 'upstream_url' => 'up2' } }
    let(:api1) { Kong::Resources::API.new(api1_attrs) }
    let(:api2) { Kong::Resources::API.new(api2_attrs) }

    before do
      allow(connection).to receive(:get)
        .with(apis_path, {}).and_return('total' => 2, 'data' => [api1_attrs, api2_attrs])
    end
    it { is_expected.to match_array([api1, api2]) }
  end

  describe '#find' do
    subject(:find_api) { client.find(api_id) }

    before do
      allow(connection).to receive(:get)
        .with(api_path).and_return(id: api_id, name: name, upstream_url: upstream)
      find_api
    end

    it { is_expected.to eq(api) }
    it { expect(connection).to have_received(:get).with(api_path) }
  end

  shared_examples 'find_by with match' do
    before do
      allow(connection).to receive(:get)
        .with(apis_path, name: name)
        .and_return('total' => 1, 'data' => [{
                      'id' => api_id, 'name' => name, 'upstream_url' => upstream
                    }])
      find_api
    end

    it { is_expected.to eq(api) }
    it { expect(connection).to have_received(:get) }
  end

  shared_context 'with empty api list response' do
    before do
      allow(connection).to receive(:get)
        .with(apis_path, name: name).and_return('total' => 0, 'data' => [])
    end
  end

  describe '#find_by' do
    subject(:find_api) { client.find_by(name: name) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty api list response'
      before { find_api }
      it { is_expected.to be_nil }
      it { expect(connection).to have_received(:get) }
    end
  end

  describe '#find_by' do
    subject(:find_api) { client.find_by(name: name, hosts: 'host') }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty api list response'
      before { find_api }
      it { is_expected.to be_nil }
      it { expect(connection).to have_received(:get) }
    end
  end

  describe '#find_by!' do
    subject(:find_api) { client.find_by!(name: name) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty api list response'
      it { is_expected_on_call.to raise_error(Kong::Error, /Resource not found/) }
    end
  end

  describe '#find_by_or_create_by' do
    subject(:find_api) { client.find_or_create_by(name: name) }

    it_behaves_like 'find_by with match'

    context 'with no match and no block' do
      let(:api) { Kong::Resources::API.new(id: api_id, name: name) }

      include_context 'with empty api list response'
      before do
        allow(connection).to receive(:create)
          .with(apis_path, 'name' => name).and_return(id: api_id, name: name)
        find_api
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(api) }
    end

    context 'with no match and block' do
      subject(:find_api) do
        client.find_or_create_by(name: name) do |api|
          api.upstream_url = upstream
        end
      end

      include_context 'with empty api list response'
      before do
        allow(connection).to receive(:create)
          .with(apis_path, 'name' => name, 'upstream_url' => upstream)
          .and_return(id: api_id, name: name, upstream_url: upstream)
        find_api
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(api) }
    end
  end
end
