# frozen_string_literal: true

require_relative 'base'

module Kong
  module Resources
    # api resource
    class Plugin < Base
      attr_accessor :id, :created_at, :config, :enabled, :name
    end
  end
end
