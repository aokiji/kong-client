# frozen_string_literal: true

require 'faraday'
require 'kong/error'

module Kong
  # connection wrapper
  class Connection
    # http response handler
    class ResponseHandler
      attr_reader :response, :expected_status

      def initialize(response, expected_status: 200)
        @response = response
        @expected_status = expected_status
      end

      def json_body
        JSON.parse(parse_body)
      end

      def status_ok?
        body = response.body
        status = response.status
        raise Error.new(status, body) if status != expected_status
      end

      private

      def parse_body
        @_parse_body ||= begin
          body = response.body
          status_ok?
          body
        end
      end
    end

    def initialize(*args)
      @http_client = Faraday.new(*args)
    end

    def get(*args)
      response = @http_client.get(*args)
      ResponseHandler.new(response).json_body
    end

    def create(*args)
      response = @http_client.post(*args)
      ResponseHandler.new(response, expected_status: 201).json_body
    end

    def update(*args)
      response = @http_client.patch(*args)
      ResponseHandler.new(response).json_body
    end

    def delete(*args)
      response = @http_client.delete(*args)
      ResponseHandler.new(response, expected_status: 204).status_ok?
    end

    def log_requests(*args)
      @http_client.builder.build do |connection|
        connection.instance_eval do
          request :url_encoded
          response :logger, *args
          adapter Faraday.default_adapter
        end
      end
    end
  end
end
