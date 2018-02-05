# frozen_string_literal: true

require 'kong/clients/base'
require 'kong/resources/plugins/jwt'

module Kong
  module Clients
    module Plugins
      # basic auth client
      class JWT < Clients::Base
        resources :jwt, class_name: 'JWT'
        searchable_by :id, :key, :consumer_id
      end
    end
  end
end
