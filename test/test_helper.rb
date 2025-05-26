ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Configure ActionCable for testing
ActionCable.server.config.cable = { "adapter" => "async" }

# Configure secret key for JWT
Rails.application.credentials.secret_key_base = "test_secret_key_base"
