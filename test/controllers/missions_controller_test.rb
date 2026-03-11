require "test_helper"

class MissionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @mission = missions(:one)
  end

  test "redirects guests to sign in on index" do
    sign_out :user
    get missions_url
    assert_redirected_to new_user_session_path
  end

  test "creates a mission" do
    assert_difference("Mission.count", 1) do
      post missions_url, params: {
        mission: {
          region_id: regions(:one).id,
          freelancer_profile_id: freelancer_profiles(:one).id,
          client_contact_id: client_contacts(:one).id,
          specialty_id: specialties(:one).id,
          title: "New Mission",
          reference: "MIS-T-#{SecureRandom.hex(3)}",
          status: "open"
        }
      }
    end

    assert_redirected_to mission_path(Mission.order(:id).last)
  end

  test "rejects invalid mission" do
    assert_no_difference("Mission.count") do
      post missions_url, params: { mission: { title: "", reference: "", status: "" } }
    end

    assert_response :unprocessable_entity
  end

  test "updates a mission" do
    patch mission_url(@mission), params: { mission: { title: "Updated Mission" } }

    assert_redirected_to mission_path(@mission)
    assert_equal "Updated Mission", @mission.reload.title
  end

  test "destroys a mission" do
    victim = Mission.create!(
      region: regions(:one),
      freelancer_profile: freelancer_profiles(:one),
      client_contact: client_contacts(:one),
      specialty: specialties(:one),
      title: "Destroy Mission",
      reference: "MIS-D-#{SecureRandom.hex(3)}",
      status: "open"
    )

    assert_difference("Mission.count", -1) do
      delete mission_url(victim)
    end

    assert_redirected_to missions_path
  end
end
