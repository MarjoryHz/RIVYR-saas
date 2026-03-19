require "test_helper"

class FreelanceFinancesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as(users(:one))
  end

  test "redirects guests to sign in on show" do
    sign_out :user
    get freelance_finance_url
    assert_redirected_to new_user_session_path
  end

  test "forbids non freelance users" do
    sign_out :user
    sign_in_as(users(:two))

    get freelance_finance_url

    assert_redirected_to root_path
    assert_equal "Vous n'etes pas autorise a effectuer cette action.", flash[:alert]
  end

  test "creates a freelancer invoice when client invoice is paid" do
    placement = Placement.create!(
      mission: missions(:one),
      candidate: candidates(:one),
      status: "validated",
      annual_salary_cents: 100_000,
      placement_fee_cents: 10_000
    )
    Invoice.create!(
      placement: placement,
      invoice_type: "client",
      number: "FAC-PAID-#{SecureRandom.hex(3)}",
      status: "paid",
      issue_date: Date.current - 20,
      paid_date: Date.current - 5,
      amount_cents: 10_000
    )
    Commission.create!(
      placement: placement,
      commission_rule: "70_30",
      status: "eligible",
      gross_amount_cents: 10_000,
      rivyr_share_cents: 3_000,
      freelancer_share_cents: 7_000,
      client_payment_required: true
    )

    assert_difference("Invoice.where(invoice_type: 'freelancer').count", 1) do
      post create_freelancer_invoice_freelance_finance_url, params: { placement_id: placement.id }
    end

    assert_redirected_to dashboard_freelance_finance_path
  end

  test "creates payout request from freelancer invoice" do
    placement = Placement.create!(
      mission: missions(:one),
      candidate: candidates(:one),
      status: "validated",
      annual_salary_cents: 100_000,
      placement_fee_cents: 10_000
    )
    Invoice.create!(
      placement: placement,
      invoice_type: "client",
      number: "FAC-PAID-#{SecureRandom.hex(3)}",
      status: "paid",
      issue_date: Date.current - 20,
      paid_date: Date.current - 5,
      amount_cents: 10_000
    )
    Commission.create!(
      placement: placement,
      commission_rule: "70_30",
      status: "eligible",
      gross_amount_cents: 10_000,
      rivyr_share_cents: 3_000,
      freelancer_share_cents: 7_000,
      client_payment_required: true
    )
    freelancer_invoice = Invoice.create!(
      placement: placement,
      invoice_type: "freelancer",
      number: "FRL-#{SecureRandom.hex(3)}",
      status: "issued",
      issue_date: Date.current - 1,
      amount_cents: 7_000
    )

    assert_difference("PayoutRequest.count", 1) do
      post create_payout_request_freelance_finance_url, params: {
        invoice_id: freelancer_invoice.id,
        amount_cents: 5_000,
        billing_number: freelancer_invoice.number
      }
    end

    assert_redirected_to dashboard_freelance_finance_path
  end
end
