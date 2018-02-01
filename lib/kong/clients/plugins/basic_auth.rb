# frozen_string_literal: true

require 'kong/clients/base'
require 'kong/resources/plugins/basic_auth'

module Kong
  module Clients
    module Plugins
      # basic auth client
      class BasicAuth < Clients::Base
        resources :basic_auth
      end
    end
  end
end
