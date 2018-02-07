# frozen_string_literal: true

require_relative 'base'

module Kong
  module Resources
    # api resource
    class API < Base
      attr_accessor :id, :name, :created_at, :strip_uri, :http_if_terminated, :https_only,
                    :upstream_url, :uris, :preserve_host, :upstream_connect_timeout,
                    :upstream_read_timeout, :upstream_send_timeout, :retries, :methods,
                    :hosts
    end
  end
end
