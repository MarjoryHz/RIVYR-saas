require "test_helper"

class CommissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @commission = commissions(:one)
  end

  test "redirects guests to sign in on index" do
    sign_out :user
    get commissions_url
    assert_redirected_to new_user_session_path
  end

  test "creates a commission" do
    assert_difference("Commission.count", 1) do
      post commissions_url, params: {
        commission: {
          placement_id: placements(:two).id,
          commission_rule: "70_30",
          status: "eligible",
          gross_amount_cents: 100000,
          rivyr_share_cents: 30000,
          freelancer_share_cents: 70000,
          client_payment_required: true
        }
      }
    end

    assert_redirected_to commission_path(Commission.order(:id).last)
  end

  test "rejects invalid commission" do
    assert_no_difference("Commission.count") do
      post commissions_url, params: { commission: { placement_id: nil, commission_rule: "", status: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "updates a commission" do
    patch commission_url(@commission), params: { commission: { status: "paid" } }

    assert_redirected_to commission_path(@commission)
    assert_equal "paid", @commission.reload.status
  end

  test "destroys a commission" do
    victim = Commission.create!(placement: placements(:two), commission_rule: "70_30", status: "eligible", gross_amount_cents: 1000, rivyr_share_cents: 300, freelancer_share_cents: 700)

    assert_difference("Commission.count", -1) do
      delete commission_url(victim)
    end

    assert_redirected_to commissions_path
  end
end
