require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "is invalid without invoice and commission" do
    payment = Payment.new(status: "pending", amount_cents: 1000)

    assert_not payment.valid?
    assert_includes payment.errors[:invoice], "must exist"
    assert_includes payment.errors[:commission], "must exist"
  end

  test "is invalid with negative amount" do
    payment = Payment.new(invoice: invoices(:one), commission: commissions(:one), status: "pending", amount_cents: -1)

    assert_not payment.valid?
    assert_includes payment.errors[:amount_cents], "must be greater than or equal to 0"
  end
end
