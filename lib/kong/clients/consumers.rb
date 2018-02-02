# frozen_string_literal: true

require 'kong/resources/consumer'
require 'kong/clients/plugins/basic_auth'
require 'kong/clients/plugins/jwt'
require 'kong/error'
require_relative 'base'

module Kong
  module Clients
    # consumers client
    class Consumers < Base
      resources :consumers
      searchable_by :id, :custom_id, :username

      def basic_auth(consumer)
        Plugins::BasicAuth.new(connection, base_path: resource_path(consumer.id))
      end

      def jwt(consumer)
        Plugins::JWT.new(connection, base_path: resource_path(consumer.id))
      end
    end
  end
end
