# frozen_string_literal: true

require 'spec_helper'
require 'kong/connection'

RSpec.describe Kong::Connection do
  let(:connection) { described_class.new(url: url, headers: headers) }
  let(:headers) { { apikey: apikey } }
  let(:url) { 'http://kong:8000/admin-api' }
  let(:consumers_url) { 'http://kong:8000/admin-api/consumers' }
  let(:consumer_url) { "http://kong:8000/admin-api/consumers/#{consumer_id}" }
  let(:id) { SecureRandom.random_number(100) }
  let(:apikey) { SecureRandom.hex(16) }
  let(:consumer_id) { SecureRandom.hex(16) }
  let(:consumer_response) { { 'id' => consumer_id, 'custom_id' => id } }

  describe '#get' do
    subject(:get_consumers) { connection.get 'consumers', custom_id: id }

    let(:consumers_response) { { 'total' => 1, 'data' => [consumer_response] } }

    context 'with successful response' do
      before do
        stub_request(:get, consumers_url)
          .with(headers: headers, query: { custom_id: id })
          .to_return(status: 200, body: JSON.generate(consumers_response))
        get_consumers
      end

      it { is_expected.to eq(consumers_response) }
    end

    context 'with error response' do
      before do
        stub_request(:get, consumers_url)
          .with(headers: headers, query: { custom_id: id })
          .to_return(status: 400, body: JSON.generate(error: 'Network error'))
      end

      it { is_expected_on_call.to raise_error(Kong::Error, /Network error/) }
    end
  end

  describe '#create' do
    subject(:create_consumer) { connection.create 'consumers', custom_id: id }

    context 'with successful response' do
      before do
        stub_request(:post, consumers_url)
          .with(headers: headers, body: { custom_id: id.to_s })
          .to_return(status: 201, body: JSON.generate(consumer_response))
        create_consumer
      end

      it { is_expected.to eq(consumer_response) }
    end

    context 'with error response' do
      before do
        stub_request(:post, consumers_url)
          .with(headers: headers, body: { custom_id: id.to_s })
          .to_return(status: 400, body: JSON.generate(error: 'Already exists'))
      end

      it { is_expected_on_call.to raise_error(Kong::Error, /Already exists/) }
    end
  end

  describe '#update' do
    subject(:update_consumer) { connection.update consumer_url, custom_id: id }

    context 'with successful response' do
      before do
        stub_request(:patch, consumer_url)
          .with(headers: headers, body: { custom_id: id.to_s })
          .to_return(status: 200, body: JSON.generate(consumer_response))
        update_consumer
      end

      it { is_expected.to eq(consumer_response) }
    end

    context 'with error response' do
      before do
        stub_request(:patch, consumer_url)
          .with(headers: headers, body: { custom_id: id.to_s })
          .to_return(status: 400, body: JSON.generate(error: 'Access denied'))
      end

      it { is_expected_on_call.to raise_error(Kong::Error, /Access denied/) }
    end
  end

  describe '#delete' do
    subject(:delete_consumer) { connection.delete consumer_url }

    context 'with successful response' do
      before do
        stub_request(:delete, consumer_url)
          .with(headers: headers)
          .to_return(status: 204, body: JSON.generate(consumer_response))
        delete_consumer
      end

      it { is_expected_on_call.not_to raise_error }
    end

    context 'with error response' do
      before do
        stub_request(:delete, consumer_url)
          .with(headers: headers)
          .to_return(status: 400, body: JSON.generate(error: 'Access denied'))
      end

      it { is_expected_on_call.to raise_error(Kong::Error, /Access denied/) }
    end
  end
end
