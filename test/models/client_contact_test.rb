require "test_helper"

class ClientContactTest < ActiveSupport::TestCase
  test "is invalid without client" do
    contact = ClientContact.new(first_name: "A", last_name: "B")

    assert_not contact.valid?
    assert_includes contact.errors[:client], "must exist"
  end

  test "is invalid with malformed email" do
    contact = ClientContact.new(client: clients(:one), first_name: "A", last_name: "B", email: "bad")

    assert_not contact.valid?
    assert_includes contact.errors[:email], "is invalid"
  end
end
