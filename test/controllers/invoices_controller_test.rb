require "test_helper"

class InvoicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @invoice = invoices(:one)
  end

  test "redirects guests to sign in on index" do
    sign_out :user
    get invoices_url
    assert_redirected_to new_user_session_path
  end

  test "creates an invoice" do
    assert_difference("Invoice.count", 1) do
      post invoices_url, params: {
        invoice: {
          placement_id: placements(:two).id,
          invoice_type: "client",
          number: "FAC-T-#{SecureRandom.hex(4)}",
          status: "issued",
          amount_cents: 120000
        }
      }
    end

    assert_redirected_to invoice_path(Invoice.order(:id).last)
  end

  test "rejects invalid invoice" do
    assert_no_difference("Invoice.count") do
      post invoices_url, params: { invoice: { placement_id: nil, number: "", status: "", invoice_type: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "updates an invoice" do
    patch invoice_url(@invoice), params: { invoice: { status: "paid" } }

    assert_redirected_to invoice_path(@invoice)
    assert_equal "paid", @invoice.reload.status
  end

  test "destroys an invoice" do
    victim = Invoice.create!(placement: placements(:two), number: "FAC-D-#{SecureRandom.hex(4)}", invoice_type: "client", status: "issued", amount_cents: 1000)

    assert_difference("Invoice.count", -1) do
      delete invoice_url(victim)
    end

    assert_redirected_to invoices_path
  end
end
