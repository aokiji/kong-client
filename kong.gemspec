# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'kong/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'kong'
  s.version     = Kong::VERSION
  s.authors     = ['Acid Tango']
  s.email       = ['acidtango@acidtango.com']
  s.summary     = 'A ruby client to interact with kong.'
  s.description = <<-DESCRIPTION
                   Ruby client and utilities to work with kong
                  DESCRIPTION
  s.license     = 'MIT'

  s.files = Dir['{tasks,lib}/**/*', 'MIT-LICENSE',
                'Rakefile', 'README.md']

  s.test_files = Dir['spec/**/*']

  s.add_runtime_dependency 'faraday', '~> 0.10'

  s.add_development_dependency 'bundler', '~> 1.14'
  s.add_development_dependency 'rake', '~> 10.0'
end
