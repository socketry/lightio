if ENV['COVERAGE']
  require 'coveralls'
  Coveralls.wear!
end

require "bundler/setup"
require "lightio"
require_relative "helper_methods"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include HelperMethods
end
