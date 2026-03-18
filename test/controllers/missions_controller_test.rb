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

  test "redirects guests to sign in on my_missions" do
    sign_out :user
    get my_missions_missions_url
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

  test "freelance can access my_missions" do
    sign_out :user
    sign_in_as(users(:one))

    get my_missions_missions_url

    assert_response :success
    assert_includes @response.body, "Mes missions"
  end

  test "closing a mission as won shows mission placee and keeps the placed candidate" do
    sign_out :user
    sign_in_as(users(:one))

    mission = Mission.create!(
      region: regions(:one),
      freelancer_profile: freelancer_profiles(:one),
      client_contact: client_contacts(:one),
      specialty: specialties(:one),
      title: "Mission Gagnee",
      reference: "MIS-WON-#{SecureRandom.hex(3)}",
      status: "open",
      opened_at: Date.current,
      origin_type: "freelancer"
    )
    candidate = candidates(:two)

    patch close_by_freelance_mission_url(mission), params: {
      closure_reason: "Mission gagnee",
      candidate_id: candidate.id
    }

    assert_redirected_to my_missions_missions_path
    assert_equal "Mission gagnee", mission.reload.closure_reason
    assert_equal candidate, mission.placement.candidate

    get mission_url(mission)
    assert_response :success
    assert_includes @response.body, "Mission placée"
    assert_includes @response.body, "Candidat placé"
  end

  test "closing a mission as lost shows mission fermee and removes any placed candidate" do
    sign_out :user
    sign_in_as(users(:one))

    mission = missions(:one)
    candidate = mission.placement.candidate
    candidate.update!(status: "placed")

    patch close_by_freelance_mission_url(mission), params: {
      closure_reason: "Le client ferme le recrutement",
      closure_note: "Le poste est stoppe"
    }

    assert_redirected_to my_missions_missions_path
    assert_equal "Le client ferme le recrutement", mission.reload.closure_reason
    assert_nil mission.placement
    assert_equal "qualified", candidate.reload.status

    get my_missions_missions_url(tab: "closed")
    assert_response :success
    assert_includes @response.body, "Mission fermée"
    assert_not_includes @response.body, "Mission placée"

    get mission_url(mission)
    assert_response :success
    assert_includes @response.body, "Mission fermée"
    assert_not_includes @response.body, "Candidat placé"
  end

  test "freelance can view open library mission without client identity" do
    sign_out :user
    sign_in_as(users(:one))

    client = clients(:two)
    client.update!(legal_name: "Societe Secrete", company_size: "450")
    mission = create_library_mission!(
      title: "Mission Library Open",
      reference: "MIS-LIB-SHOW",
      freelancer_profile: freelancer_profiles(:two),
      specialty: specialties(:one),
      origin_type: "rivyr",
      status: "open"
    )

    get mission_url(mission)

    assert_response :success
    assert_not_includes @response.body, "Societe Secrete"
    assert_includes @response.body, "ETI"
  end

  test "library redirects non freelance users" do
    get library_missions_url

    assert_redirected_to missions_path
    assert_equal "La bibliotheque de missions est reservee aux freelances.", flash[:alert]
  end

  test "freelance can access library page" do
    sign_out :user
    sign_in_as(users(:one))

    create_library_mission!(
      title: "Mission RIVYR Visible",
      reference: "MIS-LIB-RIVYR",
      freelancer_profile: freelancer_profiles(:two),
      specialty: specialties(:one),
      origin_type: "rivyr",
      status: "open"
    )

    get library_missions_url

    assert_response :success
    assert_includes @response.body, "Bibliotheque de missions"
    assert_includes @response.body, "Suggestions pour vous"
  end

  test "library only shows open missions from admin pool" do
    sign_out :user
    sign_in_as(users(:one))

    create_library_mission!(
      title: "Mission Pool Admin",
      reference: "MIS-LIB-POOL-OPEN",
      freelancer_profile: freelancer_profiles(:two),
      specialty: specialties(:one),
      origin_type: "partner",
      status: "open"
    )
    create_library_mission!(
      title: "Mission Hors Pool",
      reference: "MIS-LIB-HORS-POOL",
      freelancer_profile: freelancer_profiles(:one),
      specialty: specialties(:one),
      origin_type: "rivyr",
      status: "open"
    )
    create_library_mission!(
      title: "Mission Pool Fermee",
      reference: "MIS-LIB-POOL-CLOSED",
      freelancer_profile: freelancer_profiles(:two),
      specialty: specialties(:one),
      origin_type: "rivyr",
      status: "closed"
    )

    get library_missions_url

    assert_response :success
    assert_includes @response.body, "Mission Pool Admin"
    assert_not_includes @response.body, "Mission Hors Pool"
    assert_not_includes @response.body, "Mission Pool Fermee"
  end

  test "library exposes 4 suggestions max and full library list below" do
    sign_out :user
    sign_in_as(users(:one))

    6.times do |index|
      create_library_mission!(
        title: "Mission Suggestion #{index}",
        reference: "MIS-LIB-SUGG-#{index}",
        freelancer_profile: freelancer_profiles(:two),
        specialty: specialties(:one),
        origin_type: "rivyr",
        status: "open"
      )
    end

    get library_missions_url

    assert_response :success
    assert_includes @response.body, "Suggestions pour vous"
    assert_includes @response.body, "Bibliotheque de missions disponibles"
    assert_equal 4, @response.body.scan("radial-progress").size
    assert_includes @response.body, "Mission Suggestion 5"
  end

  test "library applies q and status filters" do
    sign_out :user
    sign_in_as(users(:one))

    create_library_mission!(
      title: "Mission Filtre Cible",
      reference: "MIS-LIB-FILTER-OK",
      freelancer_profile: freelancer_profiles(:two),
      specialty: specialties(:one),
      origin_type: "client",
      status: "open"
    )
    create_library_mission!(
      title: "Mission Filtre Hors Statut",
      reference: "MIS-LIB-FILTER-KO",
      freelancer_profile: freelancer_profiles(:two),
      specialty: specialties(:one),
      origin_type: "client",
      status: "closed"
    )

    get library_missions_url, params: { q: "Cible", status: "open" }

    assert_response :success
    assert_includes @response.body, "Mission Filtre Cible"
    assert_not_includes @response.body, "Mission Filtre Hors Statut"
  end

  private

  def create_library_mission!(title:, reference:, freelancer_profile:, specialty:, origin_type:, status:)
    Mission.create!(
      region: regions(:one),
      freelancer_profile: freelancer_profile,
      client_contact: client_contacts(:two),
      specialty: specialty,
      title: title,
      reference: reference,
      status: status,
      opened_at: Date.current,
      origin_type: origin_type
    )
  end
end
