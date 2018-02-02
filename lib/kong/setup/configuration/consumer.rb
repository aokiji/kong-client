# frozen_string_literal: true

require_relative 'base'

module Kong
  module Setup
    class Configuration
      # consumer configuration
      class Consumer < Base
        attr_accessor :id, :username, :custom_id, :basic_auth, :jwt
      end
    end
  end
end
