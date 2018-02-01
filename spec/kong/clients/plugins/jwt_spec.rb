# frozen_string_literal: true

require 'spec_helper'
require 'kong/connection'
require 'kong/clients/consumers'

RSpec.describe Kong::Clients::Plugins::JWT do
  let(:jwt) do
    Kong::Resources::Plugins::JWT.new(id: jwt_id, key: key, secret: secret)
  end
  let(:client) { Kong::Clients::Consumers.new(connection).jwt(consumer) }
  let(:connection) { instance_double(Kong::Connection) }
  let(:jwts_path) { "consumers/#{consumer_id}/jwt" }
  let(:jwt_path) { "consumers/#{consumer_id}/jwt/#{jwt_id}" }
  let(:jwt_id) { SecureRandom.hex(16) }
  let(:consumer_id) { SecureRandom.hex(16) }
  let(:consumer) { Kong::Resources::Consumer.new(id: consumer_id) }
  let(:key) { SecureRandom.hex(10) }
  let(:secret) { SecureRandom.hex(20) }

  describe '#create' do
    shared_examples 'create jwt' do
      before do
        allow(connection).to receive(:create)
          .with(jwts_path, 'key' => key, 'secret' => secret)
          .and_return(id: jwt_id, key: key, secret: secret)
        create_jwt
      end

      it { is_expected.to eq(jwt) }
      it { expect(connection).to have_received(:create) }
    end

    context 'with no block' do
      subject(:create_jwt) { client.create(key: key, secret: secret) }

      it_behaves_like 'create jwt'
    end

    context 'with block' do
      subject(:create_jwt) do
        client.create do |jwt|
          jwt.key = key
          jwt.secret = secret
        end
      end

      it_behaves_like 'create jwt'
    end
  end

  describe '#update' do
    subject(:update_jwt) { client.update(jwt, secret: secret) }

    before do
      allow(connection).to receive(:update)
        .with(jwt_path, secret: secret)
        .and_return(id: jwt_id, key: key, secret: secret)
      update_jwt
    end

    it { is_expected.to eq(jwt) }
    it { expect(connection).to have_received(:update) }
  end

  describe '#delete' do
    subject(:delete_jwt) { client.delete(jwt) }

    before do
      allow(connection).to receive(:delete).with(jwt_path).and_return(true)
      delete_jwt
    end

    it { expect(connection).to have_received(:delete).with(jwt_path) }
  end

  describe '#all' do
    subject { client.all }

    let(:jwt1_attrs) { { 'id' => 1, 'key' => 'name1', 'secret' => 'up1' } }
    let(:jwt2_attrs) { { 'id' => 2, 'key' => 'name2', 'secret' => 'up2' } }
    let(:jwt1) { Kong::Resources::Plugins::JWT.new(jwt1_attrs) }
    let(:jwt2) { Kong::Resources::Plugins::JWT.new(jwt2_attrs) }

    before do
      allow(connection).to receive(:get)
        .with(jwts_path, {}).and_return('total' => 2,
                                        'data' => [jwt1_attrs, jwt2_attrs])
    end
    it { is_expected.to match_array([jwt1, jwt2]) }
  end

  describe '#find' do
    subject(:find_jwt) { client.find(jwt_id) }

    before do
      allow(connection).to receive(:get)
        .with(jwt_path).and_return(id: jwt_id, key: key, secret: secret)
      find_jwt
    end

    it { is_expected.to eq(jwt) }
    it { expect(connection).to have_received(:get).with(jwt_path) }
  end

  shared_examples 'find_by with match' do
    before do
      allow(connection).to receive(:get)
        .with(jwts_path, key: key)
        .and_return('total' => 1, 'data' => [{
                      'id' => jwt_id, 'key' => key, 'secret' => secret
                    }])
      find_jwt
    end

    it { is_expected.to eq(jwt) }
    it { expect(connection).to have_received(:get) }
  end

  shared_context 'with empty jwt list response' do
    before do
      allow(connection).to receive(:get)
        .with(jwts_path, key: key).and_return('total' => 0, 'data' => [])
    end
  end

  describe '#find_by' do
    subject(:find_jwt) { client.find_by(key: key) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty jwt list response'
      before { find_jwt }
      it { is_expected.to be_nil }
      it { expect(connection).to have_received(:get) }
    end
  end

  describe '#find_by!' do
    subject(:find_jwt) { client.find_by!(key: key) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty jwt list response'
      it { is_expected_on_call.to raise_error(Kong::Error, /Resource not found/) }
    end
  end

  describe '#find_by_or_create_by' do
    subject(:find_jwt) { client.find_or_create_by(key: key) }

    it_behaves_like 'find_by with match'

    context 'with no match and no block' do
      let(:jwt) do
        Kong::Resources::Plugins::JWT.new(id: jwt_id, key: key)
      end

      include_context 'with empty jwt list response'
      before do
        allow(connection).to receive(:create)
          .with(jwts_path, 'key' => key)
          .and_return(id: jwt_id, key: key)
        find_jwt
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(jwt) }
    end

    context 'with no match and block' do
      subject(:find_jwt) do
        client.find_or_create_by(key: key) do |jwt|
          jwt.secret = secret
        end
      end

      include_context 'with empty jwt list response'
      before do
        allow(connection).to receive(:create)
          .with(jwts_path, 'key' => key, 'secret' => secret)
          .and_return(id: jwt_id, key: key, secret: secret)
        find_jwt
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(jwt) }
    end
  end
end
