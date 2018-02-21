# frozen_string_literal: true

require_relative 'base'

module Kong
  module Setup
    class Configuration
      # plugin factory
      class Plugin < Base
        attr_accessor :name, :config

        def initialize(type, hash)
          hash ||= {}
          super hash.merge(name: type)
        end

        # :reek:FeatureEnvy
        def to_hash
          hash = super
          hash['config'] = hash['config'].clone if hash.key?('config')
          hash
        end
      end
    end
  end
end
