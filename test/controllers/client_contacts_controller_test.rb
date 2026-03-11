require "test_helper"

class ClientContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @contact = client_contacts(:one)
  end

  test "redirects guests to sign in on index" do
    sign_out :user
    get client_contacts_url
    assert_redirected_to new_user_session_path
  end

  test "creates a client contact" do
    assert_difference("ClientContact.count", 1) do
      post client_contacts_url, params: {
        client_contact: {
          client_id: clients(:one).id,
          first_name: "Nora",
          last_name: "Test",
          email: "nora.test@example.test",
          phone: "0600000000",
          job_title: "DRH",
          primary_contact: true
        }
      }
    end

    assert_redirected_to client_contact_path(ClientContact.order(:id).last)
  end

  test "rejects invalid client contact" do
    assert_no_difference("ClientContact.count") do
      post client_contacts_url, params: {
        client_contact: {
          client_id: clients(:one).id,
          first_name: "",
          last_name: "",
          email: "bad-email"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "updates a client contact" do
    patch client_contact_url(@contact), params: { client_contact: { job_title: "Head of Talent" } }

    assert_redirected_to client_contact_path(@contact)
    assert_equal "Head of Talent", @contact.reload.job_title
  end

  test "destroys a client contact" do
    victim = ClientContact.create!(client: clients(:one), first_name: "Kill", last_name: "Me")

    assert_difference("ClientContact.count", -1) do
      delete client_contact_url(victim)
    end

    assert_redirected_to client_contacts_path
  end
end
