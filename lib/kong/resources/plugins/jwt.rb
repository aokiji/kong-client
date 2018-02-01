# frozen_string_literal: true

require 'kong/resources/base'

module Kong
  module Resources
    module Plugins
      # consumer resource
      class JWT < Resources::Base
        attr_accessor :id, :secret, :key, :created_at, :consumer_id, :algorithm
      end
    end
  end
end
