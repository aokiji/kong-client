# frozen_string_literal: true

require 'spec_helper'
require 'kong/connection'
require 'kong/clients/consumers'

RSpec.describe Kong::Clients::Consumers do
  let(:consumer) do
    Kong::Resources::Consumer.new(id: consumer_id, custom_id: custom_id, username: username)
  end
  let(:client) { described_class.new(connection) }
  let(:connection) { instance_double(Kong::Connection) }
  let(:consumers_path) { 'consumers' }
  let(:consumer_path) { "consumers/#{consumer_id}" }
  let(:consumer_id) { SecureRandom.hex(16) }
  let(:custom_id) { SecureRandom.random_number(100) }
  let(:username) { 'imauser' }

  it { expect(client.basic_auth(consumer)).to be_a(Kong::Clients::Plugins::BasicAuth) }
  it { expect(client.jwt(consumer)).to be_a(Kong::Clients::Plugins::JWT) }

  describe '#create' do
    shared_examples 'create consumer' do
      before do
        allow(connection).to receive(:create)
          .with(consumers_path, 'custom_id' => custom_id, 'username' => username)
          .and_return(id: consumer_id, custom_id: custom_id, username: username)
        create_consumer
      end

      it { is_expected.to eq(consumer) }
      it { expect(connection).to have_received(:create) }
    end

    context 'with no block' do
      subject(:create_consumer) { client.create(custom_id: custom_id, username: username) }

      it_behaves_like 'create consumer'
    end

    context 'with block' do
      subject(:create_consumer) do
        client.create do |consumer|
          consumer.custom_id = custom_id
          consumer.username = username
        end
      end

      it_behaves_like 'create consumer'
    end
  end

  describe '#update' do
    subject(:update_consumer) { client.update(consumer, username: username) }

    before do
      allow(connection).to receive(:update)
        .with(consumer_path, username: username)
        .and_return(id: consumer_id, custom_id: custom_id, username: username)
      update_consumer
    end

    it { is_expected.to eq(consumer) }
    it { expect(connection).to have_received(:update) }
  end

  describe '#delete' do
    subject(:delete_consumer) { client.delete(consumer) }

    before do
      allow(connection).to receive(:delete).with(consumer_path).and_return(true)
      delete_consumer
    end

    it { expect(connection).to have_received(:delete).with(consumer_path) }
  end

  describe '#all' do
    subject { client.all }

    let(:consumer1_attrs) { { 'id' => 1, 'custom_id' => 'name1', 'username' => 'up1' } }
    let(:consumer2_attrs) { { 'id' => 2, 'custom_id' => 'name2', 'username' => 'up2' } }
    let(:consumer1) { Kong::Resources::Consumer.new(consumer1_attrs) }
    let(:consumer2) { Kong::Resources::Consumer.new(consumer2_attrs) }

    before do
      allow(connection).to receive(:get)
        .with(consumers_path, {}).and_return('total' => 2,
                                             'data' => [consumer1_attrs, consumer2_attrs])
    end
    it { is_expected.to match_array([consumer1, consumer2]) }
  end

  describe '#find' do
    subject(:find_consumer) { client.find(consumer_id) }

    before do
      allow(connection).to receive(:get)
        .with(consumer_path).and_return(id: consumer_id, custom_id: custom_id, username: username)
      find_consumer
    end

    it { is_expected.to eq(consumer) }
    it { expect(connection).to have_received(:get).with(consumer_path) }
  end

  shared_examples 'find_by with match' do
    before do
      allow(connection).to receive(:get)
        .with(consumers_path, custom_id: custom_id)
        .and_return('total' => 1, 'data' => [{
                      'id' => consumer_id, 'custom_id' => custom_id, 'username' => username
                    }])
      find_consumer
    end

    it { is_expected.to eq(consumer) }
    it { expect(connection).to have_received(:get) }
  end

  shared_context 'with empty consumer list response' do
    before do
      allow(connection).to receive(:get)
        .with(consumers_path, custom_id: custom_id).and_return('total' => 0, 'data' => [])
    end
  end

  describe '#find_by' do
    subject(:find_consumer) { client.find_by(custom_id: custom_id) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty consumer list response'
      before { find_consumer }
      it { is_expected.to be_nil }
      it { expect(connection).to have_received(:get) }
    end
    describe 'filter non searchable arguments' do
      subject(:find_consumer) { client.find_by('custom_id' => custom_id, 'created_at' => 3) }

      it_behaves_like 'find_by with match'
    end
  end

  describe '#find_by!' do
    subject(:find_consumer) { client.find_by!(custom_id: custom_id) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty consumer list response'
      it { is_expected_on_call.to raise_error(Kong::Error, /Resource not found/) }
    end
  end

  describe '#find_by_or_create_by' do
    subject(:find_consumer) { client.find_or_create_by(custom_id: custom_id) }

    it_behaves_like 'find_by with match'

    context 'with no match and no block' do
      let(:consumer) { Kong::Resources::Consumer.new(id: consumer_id, custom_id: custom_id) }

      include_context 'with empty consumer list response'
      before do
        allow(connection).to receive(:create)
          .with(consumers_path, 'custom_id' => custom_id)
          .and_return(id: consumer_id, custom_id: custom_id)
        find_consumer
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(consumer) }
    end

    context 'with no match and block' do
      subject(:find_consumer) do
        client.find_or_create_by(custom_id: custom_id) do |consumer|
          consumer.username = username
        end
      end

      include_context 'with empty consumer list response'
      before do
        allow(connection).to receive(:create)
          .with(consumers_path, 'custom_id' => custom_id, 'username' => username)
          .and_return(id: consumer_id, custom_id: custom_id, username: username)
        find_consumer
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(consumer) }
    end
  end
end
