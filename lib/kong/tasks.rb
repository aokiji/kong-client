# frozen_string_literal: true

require 'rake'

namespace :kong do
  desc 'setup kong to redirect traffic to registry'
  task setup: :environment do
    puts 'Starting kong setup'

    config = Kong::Setup::Configuration.from_file('config/kong.yml', Rails.env)
    Kong::Setup::Runner.apply(config) do |runner|
      runner.log_requests if ENV['LOG_REQUESTS'] == '1'
      log_level = ENV.fetch('LOG_LEVEL', 'INFO').upcase
      runner.logger.level = Logger.const_get(log_level)
    end
  end
end
