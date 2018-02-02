# frozen_string_literal: true

require_relative 'configuration/api'
require_relative 'configuration/consumer'

module Kong
  module Setup
    # configuration definition for setup
    class Configuration
      attr_accessor :admin_api, :apis, :plugins, :consumers

      def initialize(hash)
        hash.each do |key, value|
          method = key.tr('-', '_')
          method << '='
          public_send(method, Utils.wrap_value_type(key, value))
        end
      end

      def self.from_file(file_name, key = nil)
        file_config = YAML.safe_load(ERB.new(File.read(file_name)).result, [], [], true)
        file_config = file_config.fetch(key.to_s) if key
        new file_config
      end

      # utility module
      module Utils
        def self.wrap_value_type(key, value)
          return public_send("wrap_#{key}", value) if %w[apis plugins consumers].include?(key)
          wrap_value(value)
        end

        def self.wrap_value(value)
          return value.map { |val| wrap_value(val) } if value.is_a?(Array)
          OpenStruct.new(value)
        end

        def self.wrap_apis(value)
          apis = OpenStruct.new
          value.each { |name, api| apis[name] = API.new(api) }
          apis
        end

        def self.wrap_consumers(consumers)
          consumers.map { |consumer| Consumer.new(consumer) }
        end

        def self.wrap_plugins(value)
          value.keys.select { |key| key.include? '-' }.each do |key|
            value[key.tr('-', '_')] = value.delete(key) || {}
          end
          OpenStruct.new(value)
        end
      end
    end
  end
end
