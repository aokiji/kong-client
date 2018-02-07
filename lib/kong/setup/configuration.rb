# frozen_string_literal: true

require_relative 'configuration/api'
require_relative 'configuration/consumer'
require_relative 'configuration/plugin'

module Kong
  module Setup
    # configuration definition for setup
    class Configuration
      attr_accessor :admin_api, :apis, :plugins, :consumers

      def initialize(hash)
        set_defaults
        hash.each do |key, value|
          method = key.tr('-', '_')
          method << '_from_hash='
          send(method, value)
        end
      end

      def self.from_file(file_name, key = nil)
        file_config = YAML.safe_load(ERB.new(File.read(file_name)).result, [], [], true)
        file_config = file_config.fetch(key.to_s) if key
        return file_config.map { |conf| new conf } if file_config.is_a? Array
        new file_config
      end

      private

      def set_defaults
        self.consumers = []
        self.apis = []
        self.plugins = []
        self.admin_api = {}
      end

      def consumers_from_hash=(consumers)
        consumers.each { |consumer| self.consumers << Consumer.new(consumer) }
      end

      def apis_from_hash=(apis)
        apis.each { |name, api| self.apis << API.new({ 'name' => name }.merge(api)) }
      end

      def plugins_from_hash=(plugins)
        plugins.each do |key, plugin_config|
          self.plugins << Plugin.new(key, plugin_config)
        end
      end

      alias admin_api_from_hash= admin_api=
    end
  end
end
