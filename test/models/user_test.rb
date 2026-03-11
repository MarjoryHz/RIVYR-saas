require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is invalid without first and last name" do
    user = User.new(email: "x@example.test", password: "password123", password_confirmation: "password123")

    assert_not user.valid?
    assert_includes user.errors[:first_name], "can't be blank"
    assert_includes user.errors[:last_name], "can't be blank"
  end
end
