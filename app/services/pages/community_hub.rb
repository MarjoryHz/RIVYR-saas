module Pages
  class CommunityHub
    def initialize(controller:)
      @controller = controller
    end

    def build_view_data(channel:, reply_to:, react_to:)
      current_slug = normalized_channel(channel)
      mark_channel_read(current_slug)

      message_counts = CommunityMessage.top_level.group(:community_channel_id).count
      read_slugs = read_channels

      channels = CommunityChannel.ordered.map do |ch|
        unread = read_slugs.include?(ch.slug) ? 0 : message_counts.fetch(ch.id, 0)
        { id: ch.id, slug: ch.slug, name: ch.name, unread: unread, active: ch.slug == current_slug }
      end

      active_channel = channels.find { |ch| ch[:active] }
      db_channel = CommunityChannel.find_by(slug: active_channel[:slug])

      messages = db_channel.community_messages
                           .top_level
                           .recent_first
                           .includes(:user, :community_message_reactions, replies: [:user])
                           .map { |msg| serialize_message(msg) }

      {
        community_current_channel: active_channel[:slug],
        community_channels: channels,
        community_messages: messages,
        community_active_channel: active_channel,
        community_reply_to: messages.find { |m| m[:id] == reply_to.to_i },
        community_react_to: messages.find { |m| m[:id] == react_to.to_i },
        community_members: build_members
      }
    end

    def create_message(channel:, body:)
      db_channel = CommunityChannel.find_by!(slug: normalized_channel(channel))
      db_channel.community_messages.create!(
        user: current_user,
        body: body,
        tone: current_user.role_admin? ? "rivyr" : "member"
      )
    end

    def destroy_message(channel:, message_id:)
      message = CommunityMessage.find_by(id: message_id)
      return { error: "Message introuvable." } if message.blank?
      return { error: "Vous ne pouvez supprimer que vos propres messages." } unless message.user_id == current_user.id

      message.destroy!
      { ok: true }
    end

    def create_reply(channel:, message_id:, body:)
      db_channel = CommunityChannel.find_by!(slug: normalized_channel(channel))
      parent = db_channel.community_messages.find_by(id: message_id)
      return { error: "Message introuvable." } if parent.blank?

      db_channel.community_messages.create!(
        user: current_user,
        parent: parent,
        body: body,
        tone: current_user.role_admin? ? "rivyr" : "member"
      )
      { ok: true }
    end

    def create_reaction(channel:, message_id:, emoji:)
      message = CommunityMessage.find_by(id: message_id)
      return { error: "Message introuvable." } if message.blank?

      message.community_message_reactions.find_or_create_by!(user: current_user, emoji: emoji)
      { ok: true }
    end

    def normalized_channel(channel)
      slugs = CommunityChannel.pluck(:slug)
      channel.to_s.presence_in(slugs) || "general"
    end

    private

    attr_reader :controller

    def current_user
      controller.current_user
    end

    def session
      controller.session
    end

    def read_channels
      session[:community_read_channels] ||= []
    end

    def mark_channel_read(slug)
      session[:community_read_channels] ||= []
      session[:community_read_channels] << slug unless session[:community_read_channels].include?(slug)
    end

    def serialize_message(msg)
      reactions = msg.community_message_reactions
                     .group(:emoji)
                     .count
                     .map { |emoji, count| { emoji: emoji, count: count } }

      replies = msg.replies.order(:created_at).map do |reply|
        {
          id: reply.id,
          author: reply.user.display_name,
          role: reply.user.freelancer_profile&.specialty&.name.presence || "Freelance RIVYR",
          time: reply.created_at.strftime("%H:%M"),
          avatar: reply.user.avatar_image_path,
          body: reply.body
        }
      end

      {
        id: msg.id,
        author_id: msg.user_id,
        author: msg.user.display_name,
        role: msg.user.freelancer_profile&.specialty&.name.presence || "Freelance RIVYR",
        time: msg.created_at.strftime("%H:%M"),
        tone: msg.tone,
        avatar: msg.user.avatar_image_path,
        body: msg.body,
        reactions: reactions,
        replies: replies
      }
    end

    def build_members
      profiles = FreelancerProfile.includes(:user, :specialty).limit(4).to_a

      profiles.map do |profile|
        {
          name: profile.user.display_name,
          role: profile.specialty&.name.presence || "Freelance RIVYR",
          status: "En ligne",
          path: controller.dashboard_freelancer_profile_path(profile),
          avatar: profile.user.avatar_image_path
        }
      end
    end
  end
end
