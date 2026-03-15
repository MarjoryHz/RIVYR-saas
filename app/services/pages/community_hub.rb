module Pages
  class CommunityHub
    AVATARS = %w[
      avatars/avatar-01.png
      avatars/avatar-02.png
      avatars/avatar-03.png
      avatars/avatar-04.png
      avatars/avatar-06.png
      avatars/avatar-07.png
      avatars/avatar-08.png
      avatars/avatar-09.png
      avatars/avatar-10.png
    ].freeze

    def initialize(controller:)
      @controller = controller
    end

    def build_view_data(channel:, reply_to:, react_to:)
      current_channel = normalized_channel(channel)
      messages = merged_messages(current_channel).map(&:deep_symbolize_keys)
      channels = channel_catalog.map { |item| item.merge(active: item[:slug] == current_channel) }

      {
        community_current_channel: current_channel,
        community_channels: channels,
        community_messages: messages,
        community_active_channel: channels.find { |item| item[:active] },
        community_reply_to: messages.find { |message| message[:id] == reply_to },
        community_react_to: messages.find { |message| message[:id] == react_to },
        community_members: build_members
      }
    end

    def create_message(channel:, body:)
      session_store["custom_messages"][normalized_channel(channel)].unshift(
        {
          "id" => next_message_id,
          "author_id" => current_user.id,
          "author" => current_author_name,
          "role" => current_author_role,
          "time" => Time.current.strftime("%H:%M"),
          "tone" => "member",
          "avatar" => current_author_avatar,
          "body" => body,
          "reactions" => [],
          "replies" => [],
          "custom" => true
        }
      )
    end

    def destroy_message(channel:, message_id:)
      current_channel = normalized_channel(channel)
      message = find_message(current_channel, message_id)
      return { error: "Message introuvable." } if message.blank?
      return { error: "Vous ne pouvez supprimer que vos propres messages." } unless owned_by_current_user?(message)

      if message["custom"].present?
        session_store["custom_messages"][current_channel].reject! { |item| item["id"] == message["id"] }
      else
        session_store["deleted_ids"] << message["id"] unless session_store["deleted_ids"].include?(message["id"])
      end

      { ok: true }
    end

    def create_reply(channel:, message_id:, body:)
      current_channel = normalized_channel(channel)
      message = find_message(current_channel, message_id)
      return { error: "Message introuvable." } if message.blank?

      session_store["replies"][message["id"]] ||= []
      session_store["replies"][message["id"]] << {
        "id" => next_message_id("reply"),
        "author" => current_author_name,
        "role" => current_author_role,
        "time" => Time.current.strftime("%H:%M"),
        "avatar" => current_author_avatar,
        "body" => body
      }

      { ok: true }
    end

    def create_reaction(channel:, message_id:, emoji:)
      current_channel = normalized_channel(channel)
      message = find_message(current_channel, message_id)
      return { error: "Message introuvable." } if message.blank?

      session_store["reactions"][message["id"]] ||= []
      reaction = session_store["reactions"][message["id"]].find { |item| item["emoji"] == emoji }
      if reaction.present?
        reaction["count"] = reaction["count"].to_i + 1
      else
        session_store["reactions"][message["id"]] << { "emoji" => emoji, "count" => 1 }
      end

      { ok: true }
    end

    def normalized_channel(channel)
      channel.presence_in(channel_catalog.map { |item| item[:slug] }) || "general"
    end

    private

    attr_reader :controller

    def current_user
      controller.current_user
    end

    def session
      controller.session
    end

    def session_store
      session.delete(:community_messages)

      session[:community_state] ||= {
        "custom_messages" => {},
        "replies" => {},
        "reactions" => {},
        "deleted_ids" => []
      }

      channel_catalog.each do |channel|
        session[:community_state]["custom_messages"][channel[:slug]] ||= []
      end

      session[:community_state]
    end

    def merged_messages(channel)
      store = session_store
      deleted_ids = store["deleted_ids"]
      base_messages = default_messages.fetch(channel, []).reject { |message| deleted_ids.include?(message["id"]) }
      custom_messages = store["custom_messages"].fetch(channel, [])

      (custom_messages + base_messages).map do |message|
        merged_message = message.deep_dup
        merged_message["replies"] = (merged_message["replies"] || []) + store["replies"].fetch(merged_message["id"], [])
        merged_message["reactions"] = merge_reactions(merged_message["reactions"] || [], store["reactions"].fetch(merged_message["id"], []))
        merged_message
      end
    end

    def merge_reactions(base_reactions, extra_reactions)
      merged = base_reactions.map(&:dup)

      extra_reactions.each do |extra_reaction|
        existing_reaction = merged.find { |item| item["emoji"] == extra_reaction["emoji"] }
        if existing_reaction.present?
          existing_reaction["count"] = existing_reaction["count"].to_i + extra_reaction["count"].to_i
        else
          merged << extra_reaction.dup
        end
      end

      merged
    end

    def find_message(channel, message_id)
      merged_messages(channel).find { |message| message["id"] == message_id.to_s }
    end

    def next_message_id(prefix = "msg")
      "#{prefix}-#{SecureRandom.hex(6)}"
    end

    def current_author_name
      [ current_user&.first_name, current_user&.last_name ].compact.join(" ").presence || current_user&.email || "Membre RIVYR"
    end

    def current_author_role
      current_user&.freelancer_profile&.specialty&.name.presence || "Freelance RIVYR"
    end

    def current_author_avatar
      AVATARS[current_user.id.to_i % AVATARS.length]
    end

    def owned_by_current_user?(message)
      message["author_id"].to_i == current_user.id
    end

    def build_members
      profiles = FreelancerProfile.includes(:user).limit(4).to_a

      fallback_members.each_with_index.map do |member, index|
        profile = profiles[index]
        profile_name = [ profile&.user&.first_name, profile&.user&.last_name ].compact.join(" ").presence
        profile_role = profile&.specialty&.name.presence

        {
          name: profile_name || member[:name],
          role: profile_role || member[:role],
          status: member[:status],
          path: profile.present? ? controller.dashboard_freelancer_profile_path(profile) : controller.dashboard_freelancer_profiles_path,
          avatar: member[:avatar]
        }
      end
    end

    def fallback_members
      [
        { name: "Julie Dupont", role: "Tech & Product", status: "En ligne", avatar: "avatars/avatar-04.png" },
        { name: "Marc Leroy", role: "Industrie", status: "En ligne", avatar: "avatars/avatar-03.png" },
        { name: "Sofia Karim", role: "Finance", status: "Il y a 8 min", avatar: "avatars/avatar-08.png" },
        { name: "Claire RIVYR", role: "Equipe operations", status: "En ligne", avatar: "avatars/avatar-05.png" }
      ]
    end

    def channel_catalog
      [
        { slug: "general", name: "General", unread: 3 },
        { slug: "missions-chaudes", name: "Missions chaudes", unread: 8 },
        { slug: "industrie", name: "Industrie", unread: 0 },
        { slug: "tech-product", name: "Tech & Product", unread: 2 },
        { slug: "finance", name: "Finance", unread: 0 },
        { slug: "bonnes-pratiques", name: "Bonnes pratiques", unread: 5 }
      ]
    end

    def default_messages
      {
        "general" => [
          {
            "id" => "msg-1",
            "author_id" => nil,
            "author" => "Claire RIVYR",
            "role" => "Equipe operations",
            "time" => "09:12",
            "tone" => "rivyr",
            "avatar" => "avatars/avatar-05.png",
            "body" => "Nous avons 2 briefs sensibles qui viennent d'entrer sur des fonctions de direction industrielle. Si certains veulent un point rapide aujourd'hui, je peux partager le contexte.",
            "reactions" => [ { "emoji" => "🔥", "count" => 8 }, { "emoji" => "👏", "count" => 4 } ],
            "replies" => []
          },
          {
            "id" => "msg-2",
            "author_id" => nil,
            "author" => "Marc Leroy",
            "role" => "Industrie",
            "time" => "09:18",
            "tone" => "member",
            "avatar" => "avatars/avatar-03.png",
            "body" => "Je suis preneur. J'observe aussi une hausse des demandes avec forte attente sur la presence terrain et le pilotage multi-sites.",
            "reactions" => [ { "emoji" => "👍", "count" => 3 } ],
            "replies" => []
          },
          {
            "id" => "msg-3",
            "author_id" => nil,
            "author" => "Julie Dupont",
            "role" => "Tech & Product",
            "time" => "09:24",
            "tone" => "member",
            "avatar" => "avatars/avatar-04.png",
            "body" => "Cote product, les clients demandent en ce moment des shortlists plus courtes mais ultra argumentees. Je peux partager mon template si utile.",
            "reactions" => [ { "emoji" => "💡", "count" => 5 }, { "emoji" => "👏", "count" => 2 } ],
            "replies" => []
          }
        ],
        "missions-chaudes" => [
          {
            "id" => "msg-4",
            "author_id" => nil,
            "author" => "Claire RIVYR",
            "role" => "Equipe operations",
            "time" => "11:08",
            "tone" => "rivyr",
            "avatar" => "avatars/avatar-05.png",
            "body" => "Nouvelle mission chaude ouverte sur une direction de site dans le Nord. Niveau d'attente tres eleve sur le pilotage du changement.",
            "reactions" => [ { "emoji" => "🔥", "count" => 11 } ],
            "replies" => []
          },
          {
            "id" => "msg-5",
            "author_id" => nil,
            "author" => "Marc Leroy",
            "role" => "Industrie",
            "time" => "11:15",
            "tone" => "member",
            "avatar" => "avatars/avatar-03.png",
            "body" => "Je peux prendre le sujet si vous cherchez quelqu'un qui connait bien les environnements multisites.",
            "reactions" => [ { "emoji" => "✅", "count" => 3 } ],
            "replies" => []
          }
        ],
        "industrie" => [
          {
            "id" => "msg-6",
            "author_id" => nil,
            "author" => "Marc Leroy",
            "role" => "Industrie",
            "time" => "08:42",
            "tone" => "member",
            "avatar" => "avatars/avatar-03.png",
            "body" => "Je constate une hausse nette des demandes sur les profils operations avec forte culture terrain et management de la performance.",
            "reactions" => [ { "emoji" => "🏭", "count" => 6 } ],
            "replies" => []
          }
        ],
        "tech-product" => [
          {
            "id" => "msg-7",
            "author_id" => nil,
            "author" => "Julie Dupont",
            "role" => "Tech & Product",
            "time" => "10:03",
            "tone" => "member",
            "avatar" => "avatars/avatar-04.png",
            "body" => "Sur les roles product, les clients challengent beaucoup plus la capacite a influencer et a structurer la priorisation que le simple background startup.",
            "reactions" => [ { "emoji" => "💡", "count" => 7 } ],
            "replies" => []
          }
        ],
        "finance" => [
          {
            "id" => "msg-8",
            "author_id" => nil,
            "author" => "Sofia Karim",
            "role" => "Finance",
            "time" => "12:20",
            "tone" => "member",
            "avatar" => "avatars/avatar-08.png",
            "body" => "Les recherches DAF restent tres sensibles a la maturite du contexte actionnarial et a la capacite de structurer la fonction rapidement.",
            "reactions" => [ { "emoji" => "📊", "count" => 4 } ],
            "replies" => []
          }
        ],
        "bonnes-pratiques" => [
          {
            "id" => "msg-9",
            "author_id" => nil,
            "author" => "Claire RIVYR",
            "role" => "Equipe operations",
            "time" => "07:55",
            "tone" => "rivyr",
            "avatar" => "avatars/avatar-05.png",
            "body" => "Partage du jour : un bon message d'approche n'est pas plus long, il est plus precis. Il doit refleter le niveau de contexte et de discernement.",
            "reactions" => [ { "emoji" => "👏", "count" => 9 }, { "emoji" => "💬", "count" => 2 } ],
            "replies" => []
          }
        ]
      }
    end
  end
end
