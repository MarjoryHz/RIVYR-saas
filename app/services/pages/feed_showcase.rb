module Pages
  class FeedShowcase
    def payload
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
            author: "Claire RIVYR",
            role: "Equipe operations",
            time: "Il y a 2 h",
            badge: "Point marche",
            avatar: "avatars/avatar-05.png",
            title: "Le marche executive industrie reste tres actif sur les directions de site et les fonctions supply.",
            body: "Les briefs recus ces derniers jours confirment une acceleration sur les recrutements sensibles, avec une forte attente sur la capacite a approcher vite et bien.",
            tags: [ "Industrie", "Executive search", "Tendance marche" ],
            stats: { likes: 24, comments: 6, shares: 3 }
          },
          {
            author: "Julie Dupont",
            role: "Label RIVYR",
            time: "Ce matin",
            badge: "Retour terrain",
            avatar: "avatars/avatar-04.png",
            title: "Les clients demandent des shortlists plus courtes mais beaucoup plus argumentees.",
            body: "Ce qui fait la difference en ce moment, c'est la capacite a expliquer le fit et pas seulement a envoyer des profils. Le niveau d'exigence monte, surtout sur les postes de direction.",
            tags: [ "Shortlist", "Client", "Bonnes pratiques" ],
            stats: { likes: 18, comments: 9, shares: 1 }
          },
          {
            author: "RIVYR Collective",
            role: "Vie du collectif",
            time: "Hier",
            badge: "Collectif",
            avatar: "avatars/avatar-09.png",
            title: "Nouveau rituel partage : les signaux faibles des missions difficiles.",
            body: "Chaque vendredi, nous mettons en avant une mission complexe, les points de blocage rencontres et les leviers qui ont permis d'avancer. Une maniere concrete d'elever le niveau collectif.",
            tags: [ "Collectif", "Methodes", "RIVYR" ],
            stats: { likes: 31, comments: 12, shares: 7 }
          }
        ],
        feed_signals: [
          { label: "Missions critiques ouvertes", value: "12", tone: "text-[#ed0e64]" },
          { label: "Freelances actifs cette semaine", value: "48", tone: "text-[#5b2633]" },
          { label: "Posts les plus enregistres", value: "7", tone: "text-[#8a5a00]" }
        ],
        feed_topics: [ "Marche", "Industrie", "Tech", "Shortlists", "Client", "Signatures", "Financement", "Collectif" ],
        feed_members: [
          { name: "Julie Dupont", role: "Tech & Product", city: "Paris", avatar: "avatars/avatar-04.png" },
          { name: "Marc Leroy", role: "Industrie", city: "Lille", avatar: "avatars/avatar-03.png" },
          { name: "Sofia Karim", role: "Finance", city: "Lyon", avatar: "avatars/avatar-08.png" }
        ]
      }
    end
  end
end
