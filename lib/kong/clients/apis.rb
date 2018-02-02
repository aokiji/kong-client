# frozen_string_literal: true

require_relative 'base'
require 'kong/resources/api'

module Kong
  module Clients
    # client to manage apis
    class APIs < Base
      resources :apis, class_name: 'API'
      searchable_by :id, :name, :upstream_url, :retries
    end
  end
end
