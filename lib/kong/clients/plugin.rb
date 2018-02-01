# frozen_string_literal: true

require 'kong/resources/plugin'
require_relative 'base'

module Kong
  module Clients
    # consumers client
    class Plugin < Base
      resources :plugins
    end
  end
end
