# frozen_string_literal: true

require 'kong/client'

module Kong
  module Setup
    # runs setup with given configuration
    class Runner
      attr_reader :config

      def initialize(config)
        @config = config
      end

      def apply
        setup_consumers
        setup_apis
        setup_plugins
      end

      def self.apply(configs)
        configs = [configs] unless configs.is_a?(Array)
        configs.each { |config| Runner.new(config).apply }
      end

      private

      def client
        @client ||= Kong::Client.new(config.admin_api)
      end

      def apis_client
        client.apis
      end

      def setup_consumers
        config.consumers.each do |consumer_config|
          setup_consumer(consumer_config)
        end
      end

      def setup_consumer(consumer_config)
        consumer = client.consumers.find_or_create_by(consumer_config.to_hash)
        setup_consumer_auth(consumer, consumer_config)
      end

      def setup_consumer_auth(consumer, consumer_config)
        %w[basic_auth jwt].each do |auth_type|
          auth_config = consumer_config.public_send(auth_type)
          next unless auth_config
          client.consumers.public_send(auth_type, consumer).find_or_create_by(auth_config)
        end
      end

      def setup_apis
        config.apis.to_h.each_value do |api_config|
          setup_api(api_config)
        end
      end

      def setup_api(api_config)
        config_hash = api_config.to_hash
        api = apis_client.find_or_create_by(config_hash)
        apis_client.update(api, config_hash)
      end

      def setup_plugins
        config.plugins.to_h.each_value do |plugin_config|
          setup_plugin(plugin_config)
        end
      end

      def setup_plugin(plugin_config)
        client.plugins.find_or_create_by(plugin_config.to_hash)
      end
    end
  end
end
