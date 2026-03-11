require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @client = clients(:one)
  end

  test "redirects guests to sign in on index" do
    sign_out :user
    get clients_url
    assert_redirected_to new_user_session_path
  end

  test "creates a client" do
    assert_difference("Client.count", 1) do
      post clients_url, params: {
        client: {
          legal_name: "Acme Test #{SecureRandom.hex(4)}",
          brand_name: "Acme",
          sector: "Tech",
          company_size: "11-50",
          active: true
        }
      }
    end

    assert_redirected_to client_path(Client.order(:id).last)
  end

  test "rejects invalid client" do
    assert_no_difference("Client.count") do
      post clients_url, params: { client: { legal_name: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "updates a client" do
    patch client_url(@client), params: { client: { brand_name: "Updated Brand" } }

    assert_redirected_to client_path(@client)
    assert_equal "Updated Brand", @client.reload.brand_name
  end

  test "destroys a client" do
    victim = Client.create!(legal_name: "Delete Me #{SecureRandom.hex(3)}")

    assert_difference("Client.count", -1) do
      delete client_url(victim)
    end

    assert_redirected_to clients_path
  end
end
