# frozen_string_literal: true

require 'kong/resources/base'

module Kong
  module Resources
    module Plugins
      # consumer resource
      class BasicAuth < Resources::Base
        attr_accessor :id, :username, :password, :created_at, :consumer_id
      end
    end
  end
end
