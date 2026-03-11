ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "devise"
require "securerandom"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def sign_in_as(user = nil)
    account = user || User.create!(
      email: "test-#{SecureRandom.hex(6)}@example.test",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Test",
      last_name: "User"
    )
    sign_in(account)
    account
  end
end
