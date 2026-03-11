require "test_helper"

class CommissionTest < ActiveSupport::TestCase
  test "is invalid without placement" do
    commission = Commission.new(commission_rule: "70_30", status: "eligible", gross_amount_cents: 1000, rivyr_share_cents: 300, freelancer_share_cents: 700)

    assert_not commission.valid?
    assert_includes commission.errors[:placement], "must exist"
  end

  test "is invalid with negative amounts" do
    commission = Commission.new(placement: placements(:one), commission_rule: "70_30", status: "eligible", gross_amount_cents: -1, rivyr_share_cents: -1, freelancer_share_cents: -1)

    assert_not commission.valid?
    assert_includes commission.errors[:gross_amount_cents], "must be greater than or equal to 0"
    assert_includes commission.errors[:rivyr_share_cents], "must be greater than or equal to 0"
    assert_includes commission.errors[:freelancer_share_cents], "must be greater than or equal to 0"
  end
end
