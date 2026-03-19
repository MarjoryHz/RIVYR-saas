class FreelancerProfilesController < ApplicationController
  before_action :set_freelancer_profile, only: [ :show, :edit, :update, :destroy ]
  before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

  def index
    authorize FreelancerProfile
    @q = params[:q].to_s.strip
    @specialty_id = params[:specialty_id].to_s.strip
    @sector = params[:sector].to_s.strip
    @profile_level = params[:profile_level].to_s.strip
    @region = params[:region].to_s.strip
    @language = params[:language].to_s.strip
    @availability = params[:availability].to_s.strip
    @badge = params[:badge].to_s.strip
    @recommended_only = params[:recommended_only].to_s == "1"

    scope = policy_scope(FreelancerProfile).includes(:user, :region, :specialty, missions: [ :placement ])
    profiles = scope.to_a
    @profile_cards = profiles.each_with_object({}) { |profile, hash| hash[profile.id] = build_profile_card(profile) }

    filtered_profiles = profiles.select { |profile| profile_matches_filters?(profile, @profile_cards[profile.id]) }
    sorted_profiles = filtered_profiles.sort_by { |profile| -@profile_cards[profile.id][:rivyr_index] }

    @specialty_options = Specialty.order(:name)
    @region_options = Region.order(:name)
    @sector_options = freelancer_sector_options
    @level_options = freelancer_level_options
    @language_options = freelancer_language_options
    @availability_options = freelancer_availability_options
    @badge_options = freelancer_badge_options
    @recommended_profiles = sorted_profiles.select { |profile| @profile_cards[profile.id][:recommended] }
    @directory_intro_count = sorted_profiles.count
    @freelancer_profiles = paginate_array(sorted_profiles, per_page: 9)
  end

  def show
    authorize @freelancer_profile
    @profile_view = build_profile_view(@freelancer_profile)
  end

  def new
    @freelancer_profile = FreelancerProfile.new
    authorize @freelancer_profile
  end

  def create
    @freelancer_profile = FreelancerProfile.new(freelancer_profile_params)
    authorize @freelancer_profile

    if @freelancer_profile.save
      redirect_to @freelancer_profile, notice: "Profil freelance créé avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @freelancer_profile
  end

  def update
    authorize @freelancer_profile

    if @freelancer_profile.update(freelancer_profile_params)
      redirect_to @freelancer_profile, notice: "Profil freelance mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @freelancer_profile

    if @freelancer_profile.destroy
      redirect_to freelancer_profiles_path, status: :see_other, notice: "Profil freelance supprimé avec succès."
    else
      redirect_to @freelancer_profile, alert: "Impossible de supprimer ce profil freelance."
    end
  end

  private

  def set_freelancer_profile
    @freelancer_profile = FreelancerProfile.includes(:user, :region, :specialty, missions: [ :placement ]).find(params[:id])
  end

  def set_form_collections
    @users = if current_user.role_admin?
      User.order(:last_name, :first_name)
    else
      User.where(id: current_user.id)
    end
    @regions = Region.order(:name)
    @specialties = Specialty.order(:name)
  end

  def freelancer_profile_params
    if current_user.role_admin?
      params.require(:freelancer_profile).permit(
        :user_id,
        :region_id,
        :specialty_id,
        :operational_status,
        :availability_status,
        :bio,
        :linkedin_url,
        :website_url,
        :rivyr_score_current,
        :profile_private,
        :freelance_legal_status,
        :annual_revenue_target_eur,
        :primary_bank_account_label,
        :primary_bank_iban,
        :primary_bank_bic,
        :secondary_bank_account_label,
        :secondary_bank_iban,
        :secondary_bank_bic,
        monthly_revenue_targets_eur: {}
      )
    else
      params.require(:freelancer_profile).permit(
        :region_id,
        :specialty_id,
        :operational_status,
        :availability_status,
        :bio,
        :linkedin_url,
        :website_url,
        :rivyr_score_current,
        :profile_private,
        :freelance_legal_status,
        :annual_revenue_target_eur,
        :primary_bank_account_label,
        :primary_bank_iban,
        :primary_bank_bic,
        :secondary_bank_account_label,
        :secondary_bank_iban,
        :secondary_bank_bic,
        monthly_revenue_targets_eur: {}
      )
    end
  end

  def paginate_array(records, per_page: 9)
    total_count = records.size
    total_pages = (total_count / per_page.to_f).ceil
    total_pages = 1 if total_pages.zero?

    page = params[:page].to_i
    page = 1 if page < 1
    page = total_pages if page > total_pages

    @page = page
    @per_page = per_page
    @total_pages = total_pages
    @total_count = total_count

    records.slice((page - 1) * per_page, per_page) || []
  end

  def build_profile_card(profile)
    user = profile.user
    placements = placements_for(profile)
    missions = profile.missions.to_a
    active_missions = missions.count { |mission| mission.status.to_s.in?(%w[open in_progress]) }
    placements_count = placements.count
    success_rate = success_rate_for(profile, placements_count)
    activity = activity_metrics_for(profile, placements_count, active_missions)
    sectors = sectors_for(profile)
    tags = specialty_tags_for(profile)
    title = title_for(profile)
    rivyr_index = ((profile.rivyr_score_current.to_i.nonzero? || 78) / 10.0).round(1)
    recommended = recommended_profile?(profile, placements_count, active_missions)
    level = level_for(profile)
    languages = languages_for(profile)
    availability = availability_badge_for(profile)
    last_placement = placements.max_by(&:created_at)

    {
      name: [ user.first_name, user.last_name ].join(" "),
      initials: "#{user.first_name.to_s.first}#{user.last_name.to_s.first}".upcase,
      avatar_path: freelancer_avatar_path(profile),
      title: title,
      rivyr_index: rivyr_index,
      placements_count: placements_count,
      experience_years: experience_years_for(profile),
      active_missions: active_missions,
      success_rate: success_rate,
      tags: tags,
      sectors: sectors,
      why_text: why_text_for(profile, tags),
      recent_placement: recent_placement_label(last_placement),
      availability: availability,
      activity: activity,
      recommended: recommended,
      level: level,
      languages: languages,
      badge: recommended ? "Recommande par RIVYR" : "Label RIVYR"
    }
  end

  def freelancer_avatar_path(profile)
    seed = profile.user_id || profile.id || profile.user&.email.to_s.sum
    avatar_index = seed.to_i % 10 + 1
    "avatars/avatar-#{format('%02d', avatar_index)}.png"
  end

  def build_profile_view(profile)
    card = build_profile_card(profile)
    placements = placements_for(profile).sort_by { |placement| placement.created_at || Time.at(0) }.reverse
    {
      card: card,
      stats: {
        placements: card[:placements_count],
        active_missions: card[:active_missions],
        interviews: interviews_count_for(profile, placements.count),
        success_rate: card[:success_rate]
      },
      expertise_text: expertise_text_for(profile, card[:tags]),
      experience_points: experience_points_for(profile),
      recent_placements: placements.first(3).map { |placement| recent_placement_label(placement) },
      testimonials: testimonials_for(profile)
    }
  end

  def profile_matches_filters?(profile, card)
    matches_query = if @q.present?
      [
        card[:name],
        card[:title],
        profile.specialty&.name,
        profile.region&.name,
        card[:tags].join(" "),
        card[:sectors].join(" ")
      ].compact.join(" ").downcase.include?(@q.downcase)
    else
      true
    end

    matches_specialty = @specialty_id.blank? || profile.specialty_id.to_s == @specialty_id
    matches_sector = @sector.blank? || card[:sectors].include?(@sector)
    matches_level = @profile_level.blank? || card[:level] == @profile_level
    matches_region = @region.blank? || profile.region&.name == @region
    matches_language = @language.blank? || card[:languages].include?(@language)
    matches_availability = @availability.blank? || profile.availability_status == @availability
    matches_badge = @badge.blank? || card[:badge] == @badge
    matches_recommended = !@recommended_only || card[:recommended]

    matches_query && matches_specialty && matches_sector && matches_level && matches_region && matches_language && matches_availability && matches_badge && matches_recommended
  end

  def placements_for(profile)
    @placements_by_profile ||= {}
    @placements_by_profile[profile.id] ||= Placement.joins(:mission).where(missions: { freelancer_profile_id: profile.id }).includes(:mission).to_a
  end

  def title_for(profile)
    specialty = profile.specialty&.name.presence || "Executive Search"
    "Consultant#{'e' if profile.user.first_name.to_s.end_with?('e')} en recrutement #{specialty}"
  end

  def sectors_for(profile)
    base = {
      "Tech" => [ "Tech / SaaS", "Product" ],
      "Finance" => [ "Finance", "Private Equity" ],
      "Industrie" => [ "Industrie", "Operations" ],
      "Sales" => [ "Sales", "Go-to-market" ],
      "HR" => [ "People", "HR" ],
      "Executive search" => [ "Executive", "Leadership" ]
    }[profile.specialty&.name.to_s] || [ profile.specialty&.name.presence || "Executive", "RIVYR" ]
    base.uniq
  end

  def specialty_tags_for(profile)
    seed_tags = {
      "Tech" => %w[Product Engineering Data Scale-up],
      "Finance" => %w[Finance Controlling CFO Fintech],
      "Industrie" => %w[Industrie Operations Supply-chain Manufacturing],
      "Sales" => %w[Sales Revenue B2B Scale-up],
      "HR" => %w[People Talent HR Leadership],
      "Executive search" => %w[Executive Leadership Board Strategy]
    }[profile.specialty&.name.to_s] || [ profile.specialty&.name.to_s.presence || "Recrutement", profile.region&.name.presence || "France" ]
    seed_tags.first(4)
  end

  def why_text_for(profile, tags)
    return profile.bio.truncate(140) if profile.bio.present?

    "Specialiste des recrutements #{tags.first.to_s.downcase} dans des contextes exigeants. Forte capacite a comprendre rapidement les enjeux metier et a livrer des shortlist precises."
  end

  def recent_placement_label(placement)
    return "Aucun placement recent renseigne" if placement.blank?

    mission = placement.mission
    region = mission.region&.name || "France"
    "#{mission.title} - #{mission.client_contact.client.sector.presence || 'Secteur confidentiel'} - #{region}"
  end

  def availability_badge_for(profile)
    case profile.availability_status.to_s
    when "available"
      { label: "Disponible", icon: "🟢", classes: "bg-[#edf8f0] text-[#2f6b3c] border-[#97c6a3]" }
    when "partially_available"
      { label: "Disponible sous 2 semaines", icon: "🟡", classes: "bg-[#fff8e1] text-[#8a5a00] border-[#f2c46f]" }
    else
      { label: "Complet", icon: "🔴", classes: "bg-[#fff1f6] text-[#a33d68] border-[#d8b3c2]" }
    end
  end

  def recommended_profile?(profile, placements_count, active_missions)
    profile.rivyr_score_current.to_i >= 85 || (placements_count >= 5 && active_missions <= 3 && profile.operational_status_active?)
  end

  def level_for(profile)
    titles = profile.missions.limit(5).pluck(:title).join(" ").downcase
    return "Executive" if titles.match?(/head|vp|chief|ceo|cfo|cto|directeur/)
    return "Senior" if titles.match?(/manager|lead|responsable/)

    "Mid-level"
  end

  def languages_for(profile)
    langs = [ "Francais" ]
    langs << "Anglais" if profile.specialty&.name.to_s.in?([ "Tech", "Executive search", "Finance" ])
    langs << "Allemand" if profile.region&.name.to_s.match?(/est|grand|paris/i) && profile.specialty&.name.to_s == "Industrie"
    langs.uniq
  end

  def success_rate_for(profile, placements_count)
    score = profile.rivyr_score_current.to_i
    base = score.positive? ? (58 + (score * 0.28)).round : 74
    [[base + [ placements_count, 6 ].min, 96].min, 68].max
  end

  def activity_metrics_for(profile, placements_count, active_missions)
    score = profile.rivyr_score_current.to_i
    {
      placements: [[placements_count * 12, 100].min, 18].max,
      participation: [[score.zero? ? 62 : score, 100].min, 20].max,
      satisfaction: [[success_rate_for(profile, placements_count), 100].min, 30].max,
      activity: [[(active_missions * 20) + 35, 100].min, 25].max
    }
  end

  def experience_years_for(profile)
    [ (Date.current.year - profile.created_at.year) + 4, 3 ].max
  end

  def interviews_count_for(profile, placements_count)
    missions_count = profile.missions.count
    [ (placements_count * 11) + (missions_count * 6), 24 ].max
  end

  def expertise_text_for(profile, tags)
    return profile.bio if profile.bio.present?

    "#{profile.user.first_name} accompagne les entreprises sur des recrutements cles autour de #{tags.first(3).join(', ')}. Son approche combine exigence de shortlist, comprehension fine du besoin et pilotage serre du process."
  end

  def experience_points_for(profile)
    specialty = profile.specialty&.name.presence || "recrutement"
    [
      "Ancien#{'ne' if profile.user.first_name.to_s.end_with?('e')} operationnel#{'le' if profile.user.first_name.to_s.end_with?('e')} du secteur #{specialty.downcase}",
      "#{experience_years_for(profile)} ans d experience dans des recrutements exigeants",
      "Habitude des contextes a forte confidentialite et des roles structurants"
    ]
  end

  def testimonials_for(profile)
    company = sectors_for(profile).first
    [
      {
        author: "CEO - #{company}",
        body: "#{profile.user.first_name} comprend tres vite les enjeux et propose des shortlist tres pertinentes."
      },
      {
        author: "DRH - Groupe #{company}",
        body: "Execution rigoureuse, communication fluide et vraie capacite a challenger le brief."
      }
    ]
  end

  def freelancer_sector_options
    [ "Tech / SaaS", "Finance", "Industrie", "Sales", "HR", "Executive" ]
  end

  def freelancer_level_options
    [ "Executive", "Senior", "Mid-level" ]
  end

  def freelancer_language_options
    [ "Francais", "Anglais", "Allemand" ]
  end

  def freelancer_availability_options
    FreelancerProfile.availability_statuses.keys
  end

  def freelancer_badge_options
    [ "Label RIVYR", "Recommande par RIVYR" ]
  end
end
