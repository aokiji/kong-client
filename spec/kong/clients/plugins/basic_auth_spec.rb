# frozen_string_literal: true

require 'spec_helper'
require 'kong/connection'
require 'kong/clients/consumers'

RSpec.describe Kong::Clients::Plugins::BasicAuth do
  let(:basic_auth) do
    Kong::Resources::Plugins::BasicAuth.new(id: basic_auth_id, password: password,
                                            username: username)
  end
  let(:client) { Kong::Clients::Consumers.new(connection).basic_auth(consumer) }
  let(:connection) { instance_double(Kong::Connection) }
  let(:basic_auths_path) { "consumers/#{consumer_id}/basic-auth" }
  let(:basic_auth_path) { "consumers/#{consumer_id}/basic-auth/#{basic_auth_id}" }
  let(:basic_auth_id) { SecureRandom.hex(16) }
  let(:consumer_id) { SecureRandom.hex(16) }
  let(:consumer) { Kong::Resources::Consumer.new(id: consumer_id) }
  let(:password) { SecureRandom.hex(10) }
  let(:username) { 'imauser' }

  describe '#create' do
    shared_examples 'create basic_auth' do
      before do
        allow(connection).to receive(:create)
          .with(basic_auths_path, 'password' => password, 'username' => username)
          .and_return(id: basic_auth_id, password: password, username: username)
        create_basic_auth
      end

      it { is_expected.to eq(basic_auth) }
      it { expect(connection).to have_received(:create) }
    end

    context 'with no block' do
      subject(:create_basic_auth) { client.create(password: password, username: username) }

      it_behaves_like 'create basic_auth'
    end

    context 'with block' do
      subject(:create_basic_auth) do
        client.create do |basic_auth|
          basic_auth.password = password
          basic_auth.username = username
        end
      end

      it_behaves_like 'create basic_auth'
    end
  end

  describe '#update' do
    subject(:update_basic_auth) { client.update(basic_auth, username: username) }

    before do
      allow(connection).to receive(:update)
        .with(basic_auth_path, username: username)
        .and_return(id: basic_auth_id, password: password, username: username)
      update_basic_auth
    end

    it { is_expected.to eq(basic_auth) }
    it { expect(connection).to have_received(:update) }
  end

  describe '#delete' do
    subject(:delete_basic_auth) { client.delete(basic_auth) }

    before do
      allow(connection).to receive(:delete).with(basic_auth_path).and_return(true)
      delete_basic_auth
    end

    it { expect(connection).to have_received(:delete).with(basic_auth_path) }
  end

  describe '#all' do
    subject { client.all }

    let(:basic_auth1_attrs) { { 'id' => 1, 'password' => 'name1', 'username' => 'up1' } }
    let(:basic_auth2_attrs) { { 'id' => 2, 'password' => 'name2', 'username' => 'up2' } }
    let(:basic_auth1) { Kong::Resources::Plugins::BasicAuth.new(basic_auth1_attrs) }
    let(:basic_auth2) { Kong::Resources::Plugins::BasicAuth.new(basic_auth2_attrs) }

    before do
      allow(connection).to receive(:get)
        .with(basic_auths_path, {}).and_return('total' => 2,
                                               'data' => [basic_auth1_attrs, basic_auth2_attrs])
    end
    it { is_expected.to match_array([basic_auth1, basic_auth2]) }
  end

  describe '#find' do
    subject(:find_basic_auth) { client.find(basic_auth_id) }

    before do
      allow(connection).to receive(:get)
        .with(basic_auth_path).and_return(id: basic_auth_id, password: password, username: username)
      find_basic_auth
    end

    it { is_expected.to eq(basic_auth) }
    it { expect(connection).to have_received(:get).with(basic_auth_path) }
  end

  shared_examples 'find_by with match' do
    before do
      allow(connection).to receive(:get)
        .with(basic_auths_path, username: username)
        .and_return('total' => 1, 'data' => [{
                      'id' => basic_auth_id, 'password' => password, 'username' => username
                    }])
      find_basic_auth
    end

    it { is_expected.to eq(basic_auth) }
    it { expect(connection).to have_received(:get) }
  end

  shared_context 'with empty basic_auth list response' do
    before do
      allow(connection).to receive(:get)
        .with(basic_auths_path, username: username).and_return('total' => 0, 'data' => [])
    end
  end

  describe '#find_by' do
    subject(:find_basic_auth) { client.find_by(username: username) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty basic_auth list response'
      before { find_basic_auth }
      it { is_expected.to be_nil }
      it { expect(connection).to have_received(:get) }
    end
  end

  describe '#find_by!' do
    subject(:find_basic_auth) { client.find_by!(username: username) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty basic_auth list response'
      it { is_expected_on_call.to raise_error(Kong::Error, /Resource not found/) }
    end
  end

  describe '#find_by_or_create_by' do
    subject(:find_basic_auth) { client.find_or_create_by(username: username) }

    it_behaves_like 'find_by with match'

    context 'with no match and no block' do
      let(:basic_auth) do
        Kong::Resources::Plugins::BasicAuth.new(id: basic_auth_id, username: username)
      end

      include_context 'with empty basic_auth list response'
      before do
        allow(connection).to receive(:create)
          .with(basic_auths_path, 'username' => username)
          .and_return(id: basic_auth_id, username: username)
        find_basic_auth
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(basic_auth) }
    end

    context 'with no match and block' do
      subject(:find_basic_auth) do
        client.find_or_create_by(username: username) do |basic_auth|
          basic_auth.password = password
        end
      end

      include_context 'with empty basic_auth list response'
      before do
        allow(connection).to receive(:create)
          .with(basic_auths_path, 'password' => password, 'username' => username)
          .and_return(id: basic_auth_id, password: password, username: username)
        find_basic_auth
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(basic_auth) }
    end
  end
end
