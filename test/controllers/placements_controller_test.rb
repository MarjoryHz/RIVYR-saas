require "test_helper"

class PlacementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @placement = placements(:one)
  end

  test "redirects guests to sign in on index" do
    sign_out :user
    get placements_url
    assert_redirected_to new_user_session_path
  end

  test "creates a placement" do
    assert_difference("Placement.count", 1) do
      post placements_url, params: {
        placement: {
          mission_id: missions(:two).id,
          candidate_id: candidates(:two).id,
          status: "validated"
        }
      }
    end

    assert_redirected_to placement_path(Placement.order(:id).last)
  end

  test "rejects invalid placement" do
    assert_no_difference("Placement.count") do
      post placements_url, params: { placement: { mission_id: nil, candidate_id: nil, status: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "updates a placement" do
    patch placement_url(@placement), params: { placement: { status: "invoiced" } }

    assert_redirected_to placement_path(@placement)
    assert_equal "invoiced", @placement.reload.status
  end

  test "destroys a placement" do
    victim = Placement.create!(mission: missions(:two), candidate: candidates(:two), status: "validated")

    assert_difference("Placement.count", -1) do
      delete placement_url(victim)
    end

    assert_redirected_to placements_path
  end
end
