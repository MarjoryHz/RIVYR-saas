require "test_helper"

class FreelancerProfileTest < ActiveSupport::TestCase
  test "is invalid without user" do
    profile = FreelancerProfile.new(specialty: specialties(:one))

    assert_not profile.valid?
    assert_includes profile.errors[:user], "must exist"
  end

  test "is invalid with negative score" do
    profile = FreelancerProfile.new(user: users(:one), specialty: specialties(:one), rivyr_score_current: -1)

    assert_not profile.valid?
    assert_includes profile.errors[:rivyr_score_current], "must be greater than or equal to 0"
  end

  test "normalizes monthly revenue targets" do
    profile = FreelancerProfile.new(
      user: users(:one),
      region: regions(:one),
      specialty: specialties(:one),
      monthly_revenue_targets_eur: { "1" => "10000", "12" => "25000" }
    )

    assert profile.valid?
    assert_equal 10_000, profile.monthly_revenue_targets_eur["01"]
    assert_equal 25_000, profile.monthly_revenue_targets_eur["12"]
  end
end
