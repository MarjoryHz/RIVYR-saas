module ApplicationHelper
  def euro_display(value)
    value.to_s.gsub(/\s*EUR\b/i, "€")
  end

  def client_logo_src(value)
    logo = value.to_s.strip
    return if logo.blank?
    return logo if logo.start_with?("data:", "http://", "https://")

    logical_path = logo.sub(%r{\A/assets/}, "")
    asset_path(logical_path)
  rescue StandardError
    logo
  end

  def avatar_asset_src(record)
    logical_path =
      if record.respond_to?(:avatar_image_path)
        record.avatar_image_path
      elsif record.respond_to?(:avatar_path)
        record.avatar_path
      end

    return if logical_path.blank?
    return logical_path if logical_path.start_with?("data:", "http://", "https://")

    asset_path(logical_path.sub(%r{\A/assets/}, ""))
  rescue StandardError
    logical_path
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
