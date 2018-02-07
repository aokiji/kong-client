# frozen_string_literal: true

require 'kong/client'
require 'logger'

module Kong
  module Setup
    # runs setup with given configuration
    class Runner
      attr_reader :config
      attr_accessor :logger

      CONSUMER_AUTH_TYPES = %w[basic_auth jwt].freeze

      def initialize(config, logger: Logger.new(STDOUT))
        @config = config
        @logger = logger
      end

      def apply
        logger.info 'Starting setup'
        setup_consumers
        setup_apis
        setup_plugins
        logger.info 'Finished setup'
      end

      def self.apply(configs)
        configs = [configs] unless configs.is_a?(Array)
        configs.each { |config| Runner.new(config).apply }
      end

      private

      def client
        @client ||= begin
          admin_api_config = config.admin_api
          logger.info "Connecting via #{admin_api_config}"
          Kong::Client.new(admin_api_config)
        end
      end

      def apis_client
        client.apis
      end

      def setup_consumers
        logger.info 'Configuring consumers'
        config.consumers.each do |consumer_config|
          setup_consumer(consumer_config)
        end
      end

      def setup_consumer(consumer_config)
        config_hash = consumer_config.to_hash
        CONSUMER_AUTH_TYPES.each { |type| config_hash.delete(type) }
        consumer = client.consumers.find_or_create_by(config_hash)
        setup_consumer_auth(consumer, consumer_config)
      end

      def setup_consumer_auth(consumer, consumer_config)
        CONSUMER_AUTH_TYPES.each do |auth_type|
          auth_config = consumer_config.public_send(auth_type)
          next unless auth_config
          client.consumers.public_send(auth_type, consumer).find_or_create_by(auth_config)
        end
      end

      def setup_apis
        logger.info 'Configuring apis'
        config.apis.each do |api_config|
          logger.info "  * #{api_config.name}"
          setup_api(api_config)
        end
      end

      def setup_api(api_config)
        config_hash = api_config.to_hash
        api = apis_client.find_or_create_by(config_hash)
        apis_client.update(api, config_hash)
      end

      def setup_plugins
        logger.info 'Configuring plugins'
        config.plugins.each do |plugin_config|
          logger.info "  * #{plugin_config.name}"
          setup_plugin(plugin_config)
        end
      end

      def setup_plugin(plugin_config)
        config = plugin_config.to_hash
        anonymous_config = config.fetch('config', {})['anonymous']
        if anonymous_config.is_a?(Hash)
          config['config']['anonymous'] = client.consumers.find_by(anonymous_config).id
        end
        client.plugins.find_or_create_by(config)
      end
    end
  end
end
