# frozen_string_literal: true

require_relative 'base'

module Kong
  module Resources
    # consumer resource
    class Consumer < Base
      attr_accessor :id, :custom_id, :username, :created_at
    end
  end
end
