module Pages
  class FeedShowcase
    def payload
      users = User.where(email: [
        "admin@rivyr.test",
        "julie.martin@rivyr.test",
        "thomas.leroy@rivyr.test",
        "sophie.vanacker@rivyr.test"
      ]).includes(:freelancer_profile).index_by(&:email)

      claire  = users["admin@rivyr.test"]
      julie   = users["julie.martin@rivyr.test"]
      thomas  = users["thomas.leroy@rivyr.test"]
      sophie  = users["sophie.vanacker@rivyr.test"]

      post_stats = compute_post_stats

      {
        feed_highlights: [
          {
            title: "Les mandats industriels repartent a la hausse",
            subtitle: "3 nouvelles missions executives ouvertes cette semaine",
            tone: "from-[#ffe1ec] via-[#fff4f8] to-white"
          },
          {
            title: "Shortlists plus rapides dans le collectif",
            subtitle: "Delai moyen en baisse sur les missions critiques",
            tone: "from-[#fff2dd] via-[#fff8ef] to-white"
          }
        ],
        feed_posts: [
          {
            author: claire&.display_name || "Claire RIVYR",
            role: "Equipe operations",
            time: "Il y a 2 h",
            badge: "Point marche",
            avatar: claire&.avatar_image_path || "avatars/avatar-05.png",
            title: "Le marche executive industrie reste tres actif sur les directions de site et les fonctions supply.",
            body: "Les briefs recus ces derniers jours confirment une acceleration sur les recrutements sensibles, avec une forte attente sur la capacite a approcher vite et bien.",
            tags: [ "Industrie", "Executive search", "Tendance marche" ],
            stats: post_stats[0]
          },
          {
            author: julie&.display_name || "Julie Martin",
            role: julie&.freelancer_profile&.specialty&.name.presence || "Label RIVYR",
            time: "Ce matin",
            badge: "Retour terrain",
            avatar: julie&.avatar_image_path || "avatars/avatar-04.png",
            title: "Les clients demandent des shortlists plus courtes mais beaucoup plus argumentees.",
            body: "Ce qui fait la difference en ce moment, c'est la capacite a expliquer le fit et pas seulement a envoyer des profils. Le niveau d'exigence monte, surtout sur les postes de direction.",
            tags: [ "Shortlist", "Client", "Bonnes pratiques" ],
            stats: post_stats[1]
          },
          {
            author: "RIVYR Collective",
            role: "Vie du collectif",
            time: "Hier",
            badge: "Collectif",
            avatar: claire&.avatar_image_path || "avatars/avatar-09.png",
            title: "Nouveau rituel partage : les signaux faibles des missions difficiles.",
            body: "Chaque vendredi, nous mettons en avant une mission complexe, les points de blocage rencontres et les leviers qui ont permis d'avancer. Une maniere concrete d'elever le niveau collectif.",
            tags: [ "Collectif", "Methodes", "RIVYR" ],
            stats: post_stats[2]
          }
        ],
        feed_signals: build_signals,
        feed_topics: [ "Marche", "Industrie", "Tech", "Shortlists", "Client", "Signatures", "Financement", "Collectif" ],
        feed_members: build_members(thomas, julie, sophie)
      }
    end

    private

    def build_members(thomas, julie, sophie)
      [
        member_hash(julie, "Tech & Product", "Paris"),
        member_hash(thomas, "Industrie", "Lille"),
        member_hash(sophie, "Finance", "Lyon")
      ]
    end

    def member_hash(user, fallback_role, city)
      {
        name: user&.display_name || "Membre RIVYR",
        role: user&.freelancer_profile&.specialty&.name.presence || fallback_role,
        city: city,
        avatar: user&.avatar_image_path || "avatars/homme-avatar.png"
      }
    end

    def compute_post_stats
      posts = ClientPost.includes(:client_post_reactions, :client_post_comments).order(created_at: :desc).limit(3).to_a

      base_likes = CommunityMessageReaction.count
      base_comments = CommunityMessage.count

      posts.each_with_index.map do |post, i|
        real_likes = post.client_post_reactions.size
        real_comments = post.client_post_comments.size
        {
          likes: real_likes.positive? ? real_likes : base_likes + (i * 7),
          comments: real_comments.positive? ? real_comments : base_comments + (i * 3),
          shares: [real_likes / 3, (base_likes / 4) + i].max
        }
      end.then { |stats| stats + Array.new([3 - stats.size, 0].max) { { likes: base_likes, comments: base_comments, shares: base_likes / 4 } } }
    end

    def build_signals
      open_missions = Mission.where(status: :open).count
      active_freelancers = FreelancerProfile.where(operational_status: :active).count
      community_messages = CommunityMessage.count

      [
        { label: "Missions critiques ouvertes", value: open_missions.to_s, tone: "text-[#ed0e64]" },
        { label: "Freelances actifs cette semaine", value: active_freelancers.to_s, tone: "text-[#5b2633]" },
        { label: "Messages dans le collectif", value: community_messages.to_s, tone: "text-[#8a5a00]" }
      ]
    end
  end
end
