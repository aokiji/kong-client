# frozen_string_literal: true

require_relative 'base'

module Kong
  module Setup
    class Configuration
      # base configuration object
      class Base
        def initialize(hash)
          hash.each do |key, value|
            method = key.to_s.tr('-', '_')
            method << '='
            public_send(method, value)
          end
        end

        def to_hash
          instance_variables.each_with_object({}) do |var, hash|
            key = var[1..-1]
            hash[key] = instance_variable_get(var)
          end
        end
      end
    end
  end
end
