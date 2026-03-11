require "test_helper"

class MissionTest < ActiveSupport::TestCase
  test "is invalid without required associations" do
    mission = Mission.new(title: "X", reference: "M-1", status: "open")

    assert_not mission.valid?
    assert_includes mission.errors[:region], "must exist"
    assert_includes mission.errors[:client_contact], "must exist"
    assert_includes mission.errors[:freelancer_profile], "must exist"
    assert_includes mission.errors[:specialty], "must exist"
  end

  test "is invalid without title reference and status" do
    mission = Mission.new(region: regions(:one), client_contact: client_contacts(:one), freelancer_profile: freelancer_profiles(:one), specialty: specialties(:one))

    assert_not mission.valid?
    assert_includes mission.errors[:title], "can't be blank"
    assert_includes mission.errors[:reference], "can't be blank"
    assert_includes mission.errors[:status], "can't be blank"
  end
end
