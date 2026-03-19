require_dependency Rails.root.join("app/services/pages/feed_showcase").to_s
require_dependency Rails.root.join("app/services/pages/community_hub").to_s

class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home, :contact, :create_contact ]

  def home
    redirect_to missions_path if user_signed_in?
  end

  def contact
    @contact_form = ContactForm.new
  end

  def create_contact
    @contact_form = ContactForm.new(contact_params)

    if @contact_form.submit
      redirect_to contact_path, notice: "Merci, votre demande a bien ete recue. Nous reviendrons vers vous rapidement."
    else
      render :contact, status: :unprocessable_entity
    end
  end

  def feed
    ::Pages::FeedShowcase.new.payload.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def community
    load_community_view_data
  end

  def training
    completion = 62 + (current_user.id.to_i % 17)
    completed_count = 4 + (current_user.id.to_i % 3)
    quiz_success_rate = 78 + (current_user.id.to_i % 11)

    @training_highlights = [
      { label: "Progression globale", value: "#{completion}%", tone: "pink" },
      { label: "Modules valides", value: "#{completed_count}/8", tone: "slate" },
      { label: "Taux de reussite quiz", value: "#{quiz_success_rate}%", tone: "emerald" },
      { label: "Certification suivante", value: "Closing expert", tone: "amber" }
    ]

    @training_tracks = [
      {
        category: "Recrutement",
        title: "Structurer une mission complexe de A a Z",
        duration: "1h45",
        level: "Intermediaire",
        progress: 100,
        quiz_score: "18/20",
        status: "Valide",
        status_tone: "emerald",
        summary: "Cadrage client, scorecard, calibration shortlist et pilotage des retours.",
        lessons: [ "Briefing & scorecard", "Sourcing cible", "Shortlist executive", "Quiz final" ],
        next_step: "Certification acquise"
      },
      {
        category: "Business",
        title: "Mieux convertir une mission ouverte en mission gagnee",
        duration: "1h20",
        level: "Avance",
        progress: 74,
        quiz_score: "Quiz a lancer",
        status: "En cours",
        status_tone: "pink",
        summary: "Positionnement, argumentaire de valeur, relances utiles et gestion du closing.",
        lessons: [ "Pitch de positionnement", "Relance a forte valeur", "Traitement des objections", "Quiz de validation" ],
        next_step: "Passer le quiz closing"
      },
      {
        category: "LinkedIn",
        title: "Construire une presence qui genere des missions",
        duration: "58 min",
        level: "Essentiel",
        progress: 42,
        quiz_score: "A preparer",
        status: "A poursuivre",
        status_tone: "amber",
        summary: "Branding freelance, messages d'approche et routines de publication utiles.",
        lessons: [ "Optimiser le profil", "Posts credibles", "Prospection douce", "Quiz de mise en pratique" ],
        next_step: "Terminer le module social selling"
      },
      {
        category: "Negociation",
        title: "Defendre ses honoraires sans perdre la mission",
        duration: "52 min",
        level: "Avance",
        progress: 0,
        quiz_score: "Non demarre",
        status: "A lancer",
        status_tone: "slate",
        summary: "Cadres de nego, ancrage de valeur et traitement des pressions tarifaires.",
        lessons: [ "Ancrer le fee", "Rythmer la nego", "Protections contractuelles", "Quiz de certification" ],
        next_step: "Commencer le parcours"
      }
    ]

    @quiz_pipeline = [
      { title: "Quiz closing", module: "Mieux convertir une mission ouverte", questions: 12, status: "Pret a lancer", tone: "pink" },
      { title: "Quiz sourcing executive", module: "Structurer une mission complexe", questions: 10, status: "Valide", tone: "emerald" },
      { title: "Quiz social selling", module: "Presence LinkedIn", questions: 8, status: "Bloque avant module 3", tone: "amber" }
    ]

    @learning_paths = [
      {
        title: "Parcours Recruteur Rivyr",
        progress: 81,
        description: "Le socle pour cadrer, sourcer, presenter et convertir sur des recrutements exigeants."
      },
      {
        title: "Parcours Commercial freelance",
        progress: 58,
        description: "Une progression orientee closing, relance client et posture de conseil."
      },
      {
        title: "Parcours Influence LinkedIn",
        progress: 36,
        description: "La routine de visibilite qui nourrit votre pipe sans bruit inutile."
      }
    ]

    @academy_feed = [
      "Nouveau module disponible : convaincre un client hesitant apres shortlist.",
      "Votre quiz sourcing executive a ete valide par le collectif Rivyr.",
      "Deux freelances ont termine la certification LinkedIn cette semaine."
    ]
  end

  def create_community_message
    body = params[:body].to_s.strip
    channel = community_hub.normalized_channel(params[:channel])
    return redirect_to dashboard_community_path(channel: channel), alert: "Le message ne peut pas etre vide." if body.blank?

    community_hub.create_message(channel: channel, body: body)

    redirect_to dashboard_community_path(channel: channel), notice: "Message envoye au collectif."
  end

  def destroy_community_message
    channel = community_hub.normalized_channel(params[:channel])
    result = community_hub.destroy_message(channel: channel, message_id: params[:id])
    return redirect_to dashboard_community_path(channel: channel), alert: result[:error] if result[:error].present?

    redirect_to dashboard_community_path(channel: channel), notice: "Message supprime."
  end

  def create_community_reply
    body = params[:body].to_s.strip
    channel = community_hub.normalized_channel(params[:channel])
    return redirect_to dashboard_community_path(channel: channel, reply_to: params[:message_id]), alert: "La reponse ne peut pas etre vide." if body.blank?

    result = community_hub.create_reply(channel: channel, message_id: params[:message_id], body: body)
    return redirect_to dashboard_community_path(channel: channel), alert: result[:error] if result[:error].present?

    redirect_to dashboard_community_path(channel: channel), notice: "Reponse ajoutee."
  end

  def create_community_reaction
    emoji = params[:emoji].to_s.strip
    channel = community_hub.normalized_channel(params[:channel])
    return redirect_to dashboard_community_path(channel: channel), alert: "Reaction invalide." if emoji.blank?

    result = community_hub.create_reaction(channel: channel, message_id: params[:message_id], emoji: emoji)
    return redirect_to dashboard_community_path(channel: channel), alert: result[:error] if result[:error].present?

    redirect_to dashboard_community_path(channel: channel), notice: "Reaction ajoutee."
  end

  def company_showcase
    @client = Client.find(params[:client_id])
    open_missions = @client.missions.where(status: "open").includes(:specialty)
    @open_missions_count = open_missions.count
    company_contacts = @client.client_contacts.includes(:user).order(primary_contact: :desc, created_at: :asc).limit(5)
    editorial = company_editorial_data[@client.legal_name] || {}

    @company_tagline      = editorial[:tagline] || @client.bio.to_s.truncate(120)
    @company_founded_year = @client.founded_year
    @company_revenue      = @client.revenue
    @company_ambiance     = @client.ambiance
    @company_values   = @client.client_values
    @company_highlights = @client.client_highlights
    @company_gallery  = editorial[:gallery]  || []

    @company_metrics = [
      { label: "Collaborateurs", value: @client.company_size },
      { label: "Secteur",        value: @client.sector },
      { label: "Localisation",   value: @client.location },
      { label: "Postes ouverts", value: open_missions.count.to_s }
    ]

    @open_missions = open_missions.limit(3)
    @client_posts = @client.client_posts.published.limit(3)
    @company_open_roles = open_missions.limit(3).map do |m|
      {
        title:    m.title,
        location: m.location.presence || @client.location,
        contract: "CDI",
        level:    m.specialty&.name || @client.sector,
        salary:   m.compensation_summary.presence || "Package selon profil",
        tag:      m.specialty&.name || @client.sector,
        pitch:    m.brief_summary.presence || "Rejoignez #{@client.brand_name} sur ce poste strategique."
      }
    end
    @company_contact_bubbles = company_contacts.map do |contact|
      full_name = [ contact.first_name, contact.last_name ].compact.join(" ").strip

      {
        full_name: full_name.presence || "Contact client",
        initials: initials_for(contact.first_name, contact.last_name),
        avatar: contact.avatar,
        job_title: contact.job_title.presence || "Equipe client"
      }
    end
    @company_subscribed = user_signed_in? && current_user.client_subscriptions.exists?(client: @client)
  end

  def company_contributions
    @client = Client.find(params[:client_id])
    @client_posts = @client.client_posts.published
  end

  def company_missions
    @client = Client.find(params[:client_id])
    @open_missions = @client.missions.where(status: "open").includes(:specialty)
  end

  private

  def initials_for(*parts)
    initials = parts.compact.flat_map { |part| part.to_s.split.map { |word| word.first } }.join.first(2)
    initials.presence&.upcase || "R"
  end

  def company_editorial_data
    {
      "Flandres Industrie SAS" => {
        tagline: "Une ETI industrielle qui combine exigence d execution et ambition de transformation.",

        highlights: [
          "Transformation de 3 sites industriels en 24 mois",
          "Plan d investissement massif sur la modernisation des operations",
          "Culture de management direct, sobre et orientee resultat"
        ],
        values: [
          { title: "Exigence utile", body: "Un niveau de jeu eleve, mais toujours aligne avec les realites du terrain et de l execution." },
          { title: "Decisions rapides", body: "Des circuits courts, une gouvernance lisible et une vraie capacite a trancher vite." },
          { title: "Impact industriel", body: "Chaque poste ouvert a une consequence concrete sur la production, la supply ou la transformation." }
        ],
        gallery: [ "Site de production modernise", "Comite de direction operations", "Atelier supply & excellence" ]
      },
      "Nord Logistics Group SAS" => {
        tagline: "Un groupe logistique multi-sites qui recrute des managers capables de piloter la performance terrain.",

        highlights: [
          "Presence sur 12 plateformes logistiques en France et en Belgique",
          "Forte culture de l amelioration continue et du management de proximite",
          "Croissance organique soutenue par des contrats grands comptes multi-annuels"
        ],
        values: [
          { title: "Performance terrain", body: "Les resultats se mesurent au quotidien, avec des indicateurs clairs et une culture du debrief." },
          { title: "Fiabilite operationnelle", body: "La promesse client repose sur la regularite d execution. Ici, la rigueur n est pas optionnelle." },
          { title: "Management de proximite", body: "Les managers de terrain sont des relais essentiels. Ils sont formes, accompagnes et valorises." }
        ],
        gallery: [ "Plateforme logistique Nord", "Equipe transport & quai", "Salle de pilotage flux" ]
      },
      "BelgoTech Solutions SA" => {
        tagline: "Une scale-up technologique qui recrute des profils produit, data et management pour accelerer.",

        highlights: [
          "Croissance de 40% en 2 ans portee par des contrats SaaS recurrents",
          "Equipe tech et produit structuree autour de squads autonomes",
          "Ambition d expansion sur le marche francais d ici 12 mois"
        ],
        values: [
          { title: "Produit avant tout", body: "La valeur delivree a l utilisateur est le critere central de toute decision." },
          { title: "Autonomie responsable", body: "Les equipes ont de la latitude. En contrepartie, les engagements sont tenus." },
          { title: "Culture de la donnee", body: "Chaque hypothese est testee, chaque decision est etayee par des metriques." }
        ],
        gallery: [ "Open space Bruxelles", "Retro produit Q1", "Demo Day interne" ]
      },
      "Artois Conseil & Transformation SAS" => {
        tagline: "Un cabinet de conseil exigeant qui recrute des profils seniors credibles face aux dirigeants.",

        highlights: [
          "Interventions exclusivement aupres de dirigeants de PME et ETI",
          "Equipe de 30 consultants, tous ex-operationnels avec un historique en entreprise",
          "Posture de conseil integre : pas de livrables sans mise en oeuvre"
        ],
        values: [
          { title: "Credibilite avant l image", body: "Ici, la valeur d un consultant se mesure a sa capacite a parler vrai face a un dirigeant." },
          { title: "Engagement de resultat", body: "Pas de recommandation sans plan d execution. Le conseil est operationnel ou il n est pas." },
          { title: "Equipe soudee", body: "La cohesion interne est un actif strategique. L ambiance est directe, stimulante et sans politique." }
        ],
        gallery: [ "Seminaire equipe conseil", "Atelier client dirigeant", "Restitution comite executif" ]
      },
      "Hexa Retail Performance SAS" => {
        tagline: "Un acteur de la distribution qui reorganise son management pour retrouver de la performance.",

        highlights: [
          "Refonte en cours du modele operationnel sur 80 points de vente",
          "Nouveau comite de direction avec une ambition de transformation claire",
          "Investissement dans des profils de direction capables de porter le changement"
        ],
        values: [
          { title: "Commerce au centre", body: "La performance commerciale est la raison d etre de chaque poste." },
          { title: "Transformation concrete", body: "Le changement est engage. Les profils qui rejoignent l entreprise en sont les acteurs directs." },
          { title: "Equipes responsabilisees", body: "La delegation est reelle. Les managers de terrain ont une vraie latitude de decision." }
        ],
        gallery: [ "Concept store modernise", "Reunion performance reseau", "Formation managers terrain" ]
      },
      "Cap Avenir Energie SAS" => {
        tagline: "Une entreprise energetique en croissance qui structure ses equipes pour passer a l echelle.",

        highlights: [
          "Portefeuille de projets en energie renouvelable en forte expansion",
          "Equipe de direction recemment renforcee avec une vision a 5 ans",
          "Culture entrepreneuriale avec une forte prise de responsabilite attendue"
        ],
        values: [
          { title: "Impact energetique", body: "Chaque projet contribue concretement a la transition. L impact est une realite operationnelle." },
          { title: "Agilite et vitesse", body: "Dans un marche en pleine mutation, les profils qui s adaptent vite ont un vrai avantage." },
          { title: "Ambition partagee", body: "Les collaborateurs construisent quelque chose. Il y a une vraie fierte collective." }
        ],
        gallery: [ "Parc solaire en construction", "Equipe projet terrain", "Reunion strategie direction" ]
      },
      "Littoral Agro Solutions SAS" => {
        tagline: "Un industriel agroalimentaire reconnu qui recrute des experts production, qualite et supply.",

        highlights: [
          "Certifications qualite internationales sur l ensemble de la chaine de production",
          "Investissements reguliers dans la modernisation des lignes industrielles",
          "Culture de l exigence technique avec un management de terrain fort"
        ],
        values: [
          { title: "Qualite non negociable", body: "Les standards sont eleves et tenus. La qualite n est pas un objectif, c est le point de depart." },
          { title: "Efficacite industrielle", body: "La performance des lignes est une priorite quotidienne." },
          { title: "Ancrage territorial", body: "L entreprise est implantee en Bretagne depuis 30 ans. Elle est un employeur de reference." }
        ],
        gallery: [ "Ligne de production automatisee", "Controle qualite laboratoire", "Equipe maintenance site" ]
      },
      "Euronextia Services SAS" => {
        tagline: "Une entreprise de services B2B en croissance qui renforce ses equipes de direction.",

        highlights: [
          "Taux de retention client superieur a 90% sur 3 ans consecutifs",
          "Expansion en cours sur de nouveaux segments B2B a fort potentiel",
          "Management horizontal avec des responsabilites larges accordees rapidement"
        ],
        values: [
          { title: "Client au centre", body: "La qualite de service est un differenciateur concret." },
          { title: "Initiative valorisee", body: "Les profils qui proposent, testent et assument leurs decisions progressent vite." },
          { title: "Croissance collective", body: "L entreprise grandit. Les collaborateurs qui la construisent grandissent avec elle." }
        ],
        gallery: [ "Espace de travail collaboratif", "Reunion client strategique", "Workshop equipe commerciale" ]
      },
      "Wallonie Engineering SA" => {
        tagline: "Un bureau d ingenierie de reference qui recrute des experts techniques et chefs de projet.",

        highlights: [
          "Projets de grande envergure dans les secteurs infrastructure, energie et industrie",
          "Equipes pluridisciplinaires avec un haut niveau de technicite",
          "Collaboration reguliere avec des donneurs d ordre publics et prives de premier plan"
        ],
        values: [
          { title: "Excellence technique", body: "La qualite des livrables est la signature de l entreprise. Elle est exigee et reconnue." },
          { title: "Complexite assumee", body: "Les projets sont ambitieux. Les profils qui reussissent ici ont le gout des problemes difficiles." },
          { title: "Collaboration multidisciplinaire", body: "La capacite a travailler en transversal est cle." }
        ],
        gallery: [ "Chantier infrastructure majeur", "Reunion bureau d etudes", "Revue technique projet" ]
      },
      "Seine Corporate Finance SAS" => {
        tagline: "Une structure finance d entreprise a taille humaine qui recrute des profils seniors exigeants.",

        highlights: [
          "Positionnement exclusif sur des mandats complexes a fort enjeu financier",
          "Equipe de 25 professionnels issus de grands groupes et cabinets de reference",
          "Culture de l excellence ou chaque profil compte et chaque mandat est strategique"
        ],
        values: [
          { title: "Expertise avant tout", body: "La valeur se construit sur la profondeur technique et la capacite a produire des analyses qui changent les decisions." },
          { title: "Confidentialite absolue", body: "Les mandats sont sensibles. La discretion est une competence autant qu une valeur." },
          { title: "Posture senior", body: "Les interlocuteurs sont des dirigeants et des investisseurs. La credibilite se construit des le premier echange." }
        ],
        gallery: [ "Salle de negociation", "Due diligence en cours", "Closing d operation" ]
      }
    }
  end

  def load_community_view_data
    community_hub.build_view_data(
      channel: params[:channel],
      reply_to: params[:reply_to],
      react_to: params[:react_to]
    ).each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def community_hub
    @community_hub ||= ::Pages::CommunityHub.new(controller: self)
  end

  def contact_params
    params.require(:contact_form).permit(:full_name, :email, :company, :subject, :message)
  end
end
