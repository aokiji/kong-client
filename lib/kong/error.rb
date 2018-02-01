# frozen_string_literal: true

module Kong
  # error entity
  class Error < StandardError
    attr_reader :status

    def initialize(status, message)
      @status = status
      super(message)
    end
  end
end
