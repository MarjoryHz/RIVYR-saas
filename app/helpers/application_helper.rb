module ApplicationHelper
  def euro_display(value)
    value.to_s.gsub(/\s*EUR\b/i, "€")
  end

  def mission_origin_badge_classes(mission)
    case mission.origin_type.to_s
    when "freelancer"
      "border-[#bfd9ff] bg-[#eef5ff] text-[#2357a5]"
    when "rivyr"
      "border-[#f3c4d3] bg-[#fff0f5] text-[#a33d68]"
    when "partner"
      "border-[#d9d3f6] bg-[#f5f2ff] text-[#6545a7]"
    else
      "border-[#d7dee7] bg-[#f6f8fb] text-[#5f6b7a]"
    end
  end
end
