require "test_helper"

class FreelancerProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as
    @profile = freelancer_profiles(:one)
  end

  test "redirects guests to sign in on index" do
    sign_out :user
    get freelancer_profiles_url
    assert_redirected_to new_user_session_path
  end

  test "creates a freelancer profile" do
    user = User.create!(
      email: "profile-#{SecureRandom.hex(4)}@example.test",
      password: "password123",
      password_confirmation: "password123",
      first_name: "New",
      last_name: "Freelancer"
    )

    assert_difference("FreelancerProfile.count", 1) do
      post freelancer_profiles_url, params: {
        freelancer_profile: {
          user_id: user.id,
          region_id: regions(:one).id,
          specialty_id: specialties(:one).id,
          operational_status: "active",
          availability_status: "available"
        }
      }
    end

    assert_redirected_to freelancer_profile_path(FreelancerProfile.order(:id).last)
  end

  test "rejects invalid freelancer profile" do
    assert_no_difference("FreelancerProfile.count") do
      post freelancer_profiles_url, params: {
        freelancer_profile: {
          user_id: nil,
          specialty_id: nil
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "updates a freelancer profile" do
    patch freelancer_profile_url(@profile), params: { freelancer_profile: { availability_status: "busy" } }

    assert_redirected_to freelancer_profile_path(@profile)
    assert_equal "busy", @profile.reload.availability_status
  end

  test "destroys a freelancer profile" do
    user = User.create!(
      email: "to-delete-#{SecureRandom.hex(4)}@example.test",
      password: "password123",
      password_confirmation: "password123",
      first_name: "To",
      last_name: "Delete"
    )
    victim = FreelancerProfile.create!(user: user, region: regions(:one), specialty: specialties(:one))

    assert_difference("FreelancerProfile.count", -1) do
      delete freelancer_profile_url(victim)
    end

    assert_redirected_to freelancer_profiles_path
  end
end
