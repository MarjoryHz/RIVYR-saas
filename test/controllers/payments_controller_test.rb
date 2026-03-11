require "test_helper"

class PaymentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @payment = payments(:one)
  end

  test "redirects guests to sign in on index" do
    sign_out :user
    get payments_url
    assert_redirected_to new_user_session_path
  end

  test "creates a payment" do
    assert_difference("Payment.count", 1) do
      post payments_url, params: {
        payment: {
          invoice_id: invoices(:one).id,
          commission_id: commissions(:one).id,
          status: "paid",
          amount_cents: 10000,
          payment_type: "client_payment",
          reference: "PAY-T-#{SecureRandom.hex(4)}"
        }
      }
    end

    assert_redirected_to payment_path(Payment.order(:id).last)
  end

  test "rejects invalid payment" do
    assert_no_difference("Payment.count") do
      post payments_url, params: { payment: { invoice_id: nil, commission_id: nil, status: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "updates a payment" do
    patch payment_url(@payment), params: { payment: { status: "pending" } }

    assert_redirected_to payment_path(@payment)
    assert_equal "pending", @payment.reload.status
  end

  test "destroys a payment" do
    victim = Payment.create!(invoice: invoices(:one), commission: commissions(:one), status: "pending", amount_cents: 1000)

    assert_difference("Payment.count", -1) do
      delete payment_url(victim)
    end

    assert_redirected_to payments_path
  end
end
