require "test_helper"

class InvoiceTest < ActiveSupport::TestCase
  test "validates unique number" do
    existing = invoices(:one)
    invoice = Invoice.new(
      placement: placements(:two),
      number: existing.number,
      invoice_type: "client",
      status: "issued",
      amount_cents: 1000
    )

    assert_not invoice.valid?
    assert_includes invoice.errors[:number], "has already been taken"
  end

  test "is invalid without required fields" do
    invoice = Invoice.new

    assert_not invoice.valid?
    assert_includes invoice.errors[:placement], "must exist"
    assert_includes invoice.errors[:number], "can't be blank"
    assert_includes invoice.errors[:invoice_type], "can't be blank"
    assert_includes invoice.errors[:status], "can't be blank"
  end
end
