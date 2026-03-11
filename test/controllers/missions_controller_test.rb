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

  test "freelance cannot access missions that do not belong to them" do
    sign_out :user
    sign_in_as(users(:one))

    foreign_mission = missions(:two)
    get mission_url(foreign_mission)

    assert_redirected_to root_path
    assert_equal "Vous n'etes pas autorise a effectuer cette action.", flash[:alert]
  end

  test "client can only access their own missions" do
    sign_out :user
    client_user = User.create!(
      email: "client-#{SecureRandom.hex(4)}@example.test",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Client",
      last_name: "User",
      status: "active",
      role: "client"
    )
    client_contacts(:one).update!(user: client_user)
    sign_in_as(client_user)

    get mission_url(missions(:one))
    assert_response :success

    get mission_url(missions(:two))
    assert_redirected_to root_path
    assert_equal "Vous n'etes pas autorise a effectuer cette action.", flash[:alert]
  end

  test "candidate can view a mission but not client identity details" do
    sign_out :user
    candidate_user = User.create!(
      email: "candidate-#{SecureRandom.hex(4)}@example.test",
      password: "password123",
      password_confirmation: "password123",
      first_name: "Candidate",
      last_name: "User",
      status: "active",
      role: "candidate"
    )
    sign_in_as(candidate_user)

    get mission_url(@mission)

    assert_response :success
    assert_includes @response.body, "Confidentiel"
  end
end
