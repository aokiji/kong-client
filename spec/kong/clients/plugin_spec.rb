# frozen_string_literal: true

require 'spec_helper'
require 'kong/connection'
require 'kong/clients/plugin'

RSpec.describe Kong::Clients::Plugin do
  let(:plugin) { Kong::Resources::Plugin.new(id: plugin_id, name: name, config: config) }
  let(:client) { described_class.new(connection) }
  let(:connection) { instance_double(Kong::Connection) }
  let(:plugins_path) { 'plugins' }
  let(:plugin_path) { "plugins/#{plugin_id}" }
  let(:plugin_id) { SecureRandom.hex(16) }
  let(:name) { SecureRandom.random_number(100) }
  let(:config) { { 'minute' => 20 } }

  describe '#create' do
    shared_examples 'create plugin' do
      before do
        allow(connection).to receive(:create)
          .with(plugins_path, 'name' => name, 'config' => config)
          .and_return(id: plugin_id, name: name, config: config)
        create_plugin
      end

      it { is_expected.to eq(plugin) }
      it { expect(connection).to have_received(:create) }
    end

    context 'with no block' do
      subject(:create_plugin) { client.create(name: name, config: config) }

      it_behaves_like 'create plugin'
    end

    context 'with block' do
      subject(:create_plugin) do
        client.create do |plugin|
          plugin.name = name
          plugin.config = config
        end
      end

      it_behaves_like 'create plugin'
    end
  end

  describe '#update' do
    subject(:update_plugin) { client.update(plugin, config: config) }

    before do
      allow(connection).to receive(:update)
        .with(plugin_path, config: config)
        .and_return(id: plugin_id, name: name, config: config)
      update_plugin
    end

    it { is_expected.to eq(plugin) }
    it { expect(connection).to have_received(:update) }
  end

  describe '#delete' do
    subject(:delete_plugin) { client.delete(plugin) }

    before do
      allow(connection).to receive(:delete).with(plugin_path).and_return(true)
      delete_plugin
    end

    it { expect(connection).to have_received(:delete).with(plugin_path) }
  end

  describe '#all' do
    subject { client.all }

    let(:plugin1_attrs) { { 'id' => 1, 'name' => 'name1', 'config' => 'up1' } }
    let(:plugin2_attrs) { { 'id' => 2, 'name' => 'name2', 'config' => 'up2' } }
    let(:plugin1) { Kong::Resources::Plugin.new(plugin1_attrs) }
    let(:plugin2) { Kong::Resources::Plugin.new(plugin2_attrs) }

    before do
      allow(connection).to receive(:get)
        .with(plugins_path, {}).and_return('total' => 2, 'data' => [plugin1_attrs, plugin2_attrs])
    end
    it { is_expected.to match_array([plugin1, plugin2]) }
  end

  describe '#find' do
    subject(:find_plugin) { client.find(plugin_id) }

    before do
      allow(connection).to receive(:get)
        .with(plugin_path).and_return(id: plugin_id, name: name, config: config)
      find_plugin
    end

    it { is_expected.to eq(plugin) }
    it { expect(connection).to have_received(:get).with(plugin_path) }
  end

  shared_examples 'find_by with match' do
    before do
      allow(connection).to receive(:get)
        .with(plugins_path, name: name)
        .and_return('total' => 1, 'data' => [{
                      'id' => plugin_id, 'name' => name, 'config' => config
                    }])
      find_plugin
    end

    it { is_expected.to eq(plugin) }
    it { expect(connection).to have_received(:get) }
  end

  shared_context 'with empty plugin list response' do
    before do
      allow(connection).to receive(:get)
        .with(plugins_path, name: name).and_return('total' => 0, 'data' => [])
    end
  end

  describe '#find_by' do
    subject(:find_plugin) { client.find_by(name: name) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty plugin list response'
      before { find_plugin }
      it { is_expected.to be_nil }
      it { expect(connection).to have_received(:get) }
    end
  end

  describe '#find_by' do
    subject(:find_plugin) { client.find_by(name: name, config: { extra: 'true' }) }

    it_behaves_like 'find_by with match'
  end

  describe '#find_by!' do
    subject(:find_plugin) { client.find_by!(name: name) }

    it_behaves_like 'find_by with match'
    context 'with no match' do
      include_context 'with empty plugin list response'
      it { is_expected_on_call.to raise_error(Kong::Error, /Resource not found/) }
    end
  end

  describe '#find_by_or_create_by' do
    subject(:find_plugin) { client.find_or_create_by(name: name) }

    it_behaves_like 'find_by with match'

    context 'with no match and no block' do
      let(:plugin) { Kong::Resources::Plugin.new(id: plugin_id, name: name) }

      include_context 'with empty plugin list response'
      before do
        allow(connection).to receive(:create)
          .with(plugins_path, 'name' => name)
          .and_return(id: plugin_id, name: name)
        find_plugin
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(plugin) }
    end

    context 'with no match and block' do
      subject(:find_plugin) do
        client.find_or_create_by(name: name) do |plugin|
          plugin.config = config
        end
      end

      include_context 'with empty plugin list response'
      before do
        allow(connection).to receive(:create)
          .with(plugins_path, 'name' => name, 'config' => config)
          .and_return(id: plugin_id, name: name, config: config)
        find_plugin
      end
      it { expect(connection).to have_received(:create) }
      it { is_expected.to eq(plugin) }
    end
  end
end
