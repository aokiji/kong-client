# frozen_string_literal: true

require 'kong/connection'
require 'kong/clients/apis'
require 'kong/clients/consumers'
require 'kong/clients/plugin'

module Kong
  # clients aggregator
  class Client
    def initialize(*args)
      @connection = Kong::Connection.new(*args)
    end

    def consumers
      Kong::Clients::Consumers.new(@connection)
    end

    def apis
      Kong::Clients::APIs.new(@connection)
    end

    def plugins
      Kong::Clients::Plugin.new(@connection)
    end

    protected

    attr_reader :connection
  end
end
