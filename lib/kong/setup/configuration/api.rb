# frozen_string_literal: true

require_relative 'base'

module Kong
  module Setup
    class Configuration
      # api configuration
      class API < Base
        attr_accessor :name, :version, :upstream_url, :strip_uri, :endpoints
        attr_writer :uris

        def uris
          @uris ||= endpoints.map { |path| "/#{version}/#{path}" }.join(',')
        end

        # :reek:FeatureEnvy
        def to_hash
          hash = super
          hash.delete('version')
          hash.delete('endpoints')
          hash['uris'] = uris
          hash
        end
      end
    end
  end
end
