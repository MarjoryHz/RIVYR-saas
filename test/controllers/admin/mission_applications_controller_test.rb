require "test_helper"

class Admin::MissionApplicationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:two)
    @admin_profile = freelancer_profiles(:two)
    @freelance_user = users(:one)
    @freelance_profile = freelancer_profiles(:one)

    @mission = Mission.create!(
      region: regions(:one),
      freelancer_profile: @admin_profile,
      client_contact: client_contacts(:one),
      specialty: specialties(:one),
      mission_type: "exclusive",
      title: "Mission validation admin",
      reference: "MIS-ADMIN-#{SecureRandom.hex(3)}",
      status: "open",
      opened_at: Date.current
    )

    @application = FreelanceMissionApplication.create!(
      mission: @mission,
      freelancer_profile: @freelance_profile,
      status: "applied",
      applied_at: Time.current
    )
  end

  test "admin can view pending mission applications" do
    sign_in_as(@admin_user)

    get admin_mission_applications_url

    assert_response :success
    assert_includes @response.body, "Validations de candidatures"
    assert_includes @response.body, @mission.title
    assert_includes @response.body, @freelance_user.email
  end

  test "admin can accept a mission application" do
    sign_in_as(@admin_user)

    patch accept_admin_mission_application_url(@application)

    assert_redirected_to admin_mission_applications_path
    assert_equal "accepted", @application.reload.status
    assert_equal @admin_user.id, @application.reviewed_by_id
    assert_equal @freelance_profile.id, @mission.reload.freelancer_profile_id
  end

  test "admin can reject a mission application with a reason" do
    sign_in_as(@admin_user)

    patch reject_admin_mission_application_url(@application), params: {
      freelance_mission_application: { review_reason: "Spécialité pas assez alignée." }
    }

    assert_redirected_to admin_mission_applications_path
    assert_equal "rejected", @application.reload.status
    assert_equal "Spécialité pas assez alignée.", @application.review_reason
    assert_equal @admin_user.id, @application.reviewed_by_id
  end

  test "freelance cannot access admin mission applications" do
    sign_in_as(@freelance_user)

    get admin_mission_applications_url

    assert_redirected_to root_path
    assert_equal "Vous n'etes pas autorise a effectuer cette action.", flash[:alert]
  end
end
