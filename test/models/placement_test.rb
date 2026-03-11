require "test_helper"

class PlacementTest < ActiveSupport::TestCase
  test "is invalid without mission and candidate" do
    placement = Placement.new(status: "validated")

    assert_not placement.valid?
    assert_includes placement.errors[:mission], "must exist"
    assert_includes placement.errors[:candidate], "must exist"
  end

  test "is invalid with negative monetary fields" do
    placement = Placement.new(mission: missions(:one), candidate: candidates(:one), status: "validated", annual_salary_cents: -1, placement_fee_cents: -1)

    assert_not placement.valid?
    assert_includes placement.errors[:annual_salary_cents], "must be greater than or equal to 0"
    assert_includes placement.errors[:placement_fee_cents], "must be greater than or equal to 0"
  end
end
