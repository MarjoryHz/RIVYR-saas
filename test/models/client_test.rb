require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "is invalid without legal_name" do
    client = Client.new

    assert_not client.valid?
    assert_includes client.errors[:legal_name], "can't be blank"
  end
end
