require "test_helper"

class CandidateTest < ActiveSupport::TestCase
  test "is invalid without first_name and last_name" do
    candidate = Candidate.new

    assert_not candidate.valid?
    assert_includes candidate.errors[:first_name], "can't be blank"
    assert_includes candidate.errors[:last_name], "can't be blank"
  end

  test "is invalid with malformed email" do
    candidate = Candidate.new(first_name: "A", last_name: "B", email: "bad")

    assert_not candidate.valid?
    assert_includes candidate.errors[:email], "is invalid"
  end
end
