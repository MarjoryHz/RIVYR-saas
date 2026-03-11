require "test_helper"

class CandidatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @candidate = candidates(:one)
  end

  test "redirects guests to sign in on index" do
    sign_out :user
    get candidates_url
    assert_redirected_to new_user_session_path
  end

  test "creates a candidate" do
    assert_difference("Candidate.count", 1) do
      post candidates_url, params: {
        candidate: {
          first_name: "John",
          last_name: "Doe",
          email: "john.doe-#{SecureRandom.hex(3)}@example.test",
          status: "new"
        }
      }
    end

    assert_redirected_to candidate_path(Candidate.order(:id).last)
  end

  test "rejects invalid candidate" do
    assert_no_difference("Candidate.count") do
      post candidates_url, params: { candidate: { first_name: "", last_name: "", email: "bad" } }
    end

    assert_response :unprocessable_entity
  end

  test "updates a candidate" do
    patch candidate_url(@candidate), params: { candidate: { status: "qualified" } }

    assert_redirected_to candidate_path(@candidate)
    assert_equal "qualified", @candidate.reload.status
  end

  test "destroys a candidate" do
    victim = Candidate.create!(first_name: "Kill", last_name: "Me")

    assert_difference("Candidate.count", -1) do
      delete candidate_url(victim)
    end

    assert_redirected_to candidates_path
  end
end
