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
    @company_metrics = [
      { label: "Collaborateurs", value: "1 250" },
      { label: "Sites en Europe", value: "14" },
      { label: "Croissance 2025", value: "+18 %" },
      { label: "Postes ouverts", value: "9" }
    ]

    @company_values = [
      {
        title: "Exigence utile",
        body: "Un niveau de jeu eleve, mais toujours aligne avec les realites du terrain et de l'execution."
      },
      {
        title: "Decisions rapides",
        body: "Des circuits courts, une gouvernance lisible et une vraie capacite a trancher vite."
      },
      {
        title: "Impact industriel",
        body: "Chaque poste ouvert a une consequence concrete sur la production, la supply ou la transformation."
      }
    ]

    @company_highlights = [
      "Transformation de 3 sites industriels en 24 mois",
      "Plan d'investissement massif sur la modernisation des operations",
      "Culture de management direct, sobre et orientee resultat"
    ]

    @company_open_roles = [
      {
        title: "Directeur de site",
        location: "Hauts-de-France",
        contract: "CDI",
        level: "Executive",
        salary: "110 000€ - 140 000€",
        tag: "Operationel",
        pitch: "Piloter un site strategique en forte phase d'optimisation et de transformation."
      },
      {
        title: "Responsable supply chain",
        location: "Lyon",
        contract: "CDI",
        level: "Senior manager",
        salary: "80 000€ - 95 000€",
        tag: "Supply",
        pitch: "Structurer les flux, fiabiliser la prevision et accompagner la croissance industrielle."
      },
      {
        title: "Directeur excellence operationnelle",
        location: "Paris",
        contract: "CDI",
        level: "Direction",
        salary: "120 000€ - 150 000€",
        tag: "Transformation",
        pitch: "Porter les programmes d'amelioration continue et l'industrialisation de nouveaux standards."
      }
    ]

    @company_gallery = [
      "Site de production modernise",
      "Comite de direction operations",
      "Atelier supply & excellence"
    ]
  end

  private

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
