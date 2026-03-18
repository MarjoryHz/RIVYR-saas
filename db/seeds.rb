# db/seeds.rb
# rails db:seed

require 'faker'

Faker::Config.locale = 'fr'

puts "============================"
puts "RIVYR SEED START"
puts "============================"

# --------------------------------------------------
# 1. Reset
# On repart d'une base propre pour garantir un seed deterministe.
# --------------------------------------------------

puts "Cleaning database..."

Payment.destroy_all
PayoutRequest.destroy_all
InvoiceNote.destroy_all
Commission.destroy_all
Invoice.destroy_all
Placement.destroy_all
FavoriteCandidate.destroy_all
Mission.destroy_all
ClientContact.destroy_all
ClientHighlight.destroy_all
ClientValue.destroy_all
Client.destroy_all
WorkExperience.destroy_all
Education.destroy_all
Contribution.destroy_all
Candidate.destroy_all
FreelancerProfile.destroy_all
User.destroy_all
Region.destroy_all
Specialty.destroy_all

puts "Database cleaned."

# --------------------------------------------------
# 2. Catalogues et jeux de donnees
# Donnees de reference reutilisees dans tout le seed.
# --------------------------------------------------

REGIONS_DATA = [
  { name: 'Hauts-de-France', options: ['Lille', 'Roubaix', 'Tourcoing', 'Villeneuve-d Ascq', 'Amiens', 'Valenciennes', 'Dunkerque'] },
  { name: 'Ile-de-France', options: ['Paris', 'Boulogne-Billancourt', 'Nanterre', 'Saint-Denis', 'Creteil'] },
  { name: 'Grand Est', options: ['Strasbourg', 'Reims', 'Metz', 'Nancy'] },
  { name: 'Normandie', options: ['Rouen', 'Caen', 'Le Havre'] },
  { name: 'Pays de la Loire', options: ['Nantes', 'Angers', 'Le Mans'] },
  { name: 'Bretagne', options: ['Rennes', 'Brest', 'Lorient'] },
  { name: 'Centre-Val de Loire', options: ['Tours', 'Orleans', 'Blois'] },
  { name: 'Nouvelle-Aquitaine', options: ['Bordeaux', 'Poitiers', 'Limoges'] },
  { name: 'Occitanie', options: ['Toulouse', 'Montpellier', 'Nimes'] },
  { name: 'Auvergne-Rhone-Alpes', options: ['Lyon', 'Grenoble', 'Clermont-Ferrand'] },
  { name: 'Bourgogne-Franche-Comte', options: ['Dijon', 'Besancon'] },
  { name: 'Provence-Alpes-Cote d Azur', options: ['Marseille', 'Nice', 'Aix-en-Provence'] },
  { name: 'Belgique', options: ['Bruxelles', 'Mons', 'Tournai', 'Mouscron', 'Liege', 'Charleroi'] }
].freeze

SPECIALTIES_DATA = [
  { name: 'Direction Generale', options: ['Directeur General', 'COO', 'Directeur de Business Unit'] },
  { name: 'Finance', options: ['DAF', 'Responsable Controle de Gestion', 'Responsable Comptable'] },
  { name: 'Ressources Humaines', options: ['DRH', 'Responsable RH', 'Talent Acquisition Manager'] },
  { name: 'Commercial', options: ['Directeur Commercial', 'Key Account Manager', 'Business Developer Senior'] },
  { name: 'Marketing', options: ['Responsable Marketing', 'Brand Manager', 'Growth Manager'] },
  { name: 'Digital & Produit', options: ['Product Manager', 'Product Owner', 'Head of Product'] },
  { name: 'Tech & Data', options: ['CTO', 'Lead Developer', 'Head of Data'] },
  { name: 'Industrie', options: ['Directeur de Site', 'Responsable Production', 'Lean Manager'] },
  { name: 'Supply Chain', options: ['Responsable Supply Chain', 'Responsable Logistique', 'Acheteur Senior'] },
  { name: 'Ingenierie', options: ['Ingenieur Methodes', 'Chef de Projet', 'Responsable Bureau d Etudes'] },
  { name: 'Maintenance', options: ['Responsable Maintenance', 'Ingenieur Fiabilite', 'Responsable Travaux Neufs'] },
  { name: 'Juridique', options: ['Responsable Juridique', 'Juriste Corporate'] }
].freeze

PREMIUM_FREELANCERS = [
  {
    email: 'claire.dumont@rivyr.test',
    first_name: 'Claire',
    last_name: 'Dumont',
    specialty: 'Direction Generale',
    region: 'Hauts-de-France',
    score: 94,
    bio: "Ex-chasseuse de tetes en cabinet, Claire intervient aujourd hui en independante sur des recrutements de dirigeants, membres de CODIR et managers de transformation. Elle est reconnue pour sa capacite a qualifier finement les enjeux politiques, humains et business d un recrutement sensible."
  },
  {
    email: 'thomas.leroy@rivyr.test',
    first_name: 'Thomas',
    last_name: 'Leroy',
    specialty: 'Industrie',
    region: 'Hauts-de-France',
    score: 91,
    bio: "Thomas accompagne des industriels, ETI et groupes sur des recrutements de direction de site, production, maintenance et supply chain. Son point fort : une lecture terrain des environnements industriels et une evaluation tres concrete du niveau d execution des candidats."
  },
  {
    email: 'sophie.vanacker@rivyr.test',
    first_name: 'Sophie',
    last_name: 'Vanacker',
    specialty: 'Ressources Humaines',
    region: 'Belgique',
    score: 92,
    bio: "Sophie intervient sur des fonctions RH strategiques et manageriales en France et en Belgique. Elle se distingue par une approche de conseil exigeante, une grande qualite d ecoute et une vraie justesse dans l evaluation des postures de leadership."
  },
  {
    email: 'antoine.mercier@rivyr.test',
    first_name: 'Antoine',
    last_name: 'Mercier',
    specialty: 'Commercial',
    region: 'Ile-de-France',
    score: 89,
    bio: "Specialiste des recrutements commerciaux, Antoine accompagne ses clients sur des fonctions de direction commerciale, developpement grands comptes et structuration d equipes de vente. Il est particulierement pertinent sur les contextes de croissance et de repositionnement marche."
  }
].freeze

STANDARD_FREELANCERS = [
  {
    email: 'julie.martin@rivyr.test',
    first_name: 'Julie',
    last_name: 'Martin',
    specialty: 'Finance',
    region: 'Ile-de-France',
    score: 84,
    bio: "Julie recrute des profils finance et pilotage de la performance pour des PME, ETI et groupes. Elle apprecie les contextes ou la technicite doit se combiner avec une vraie capacite d influence interne."
  },
  {
    email: 'arthur.delcourt@rivyr.test',
    first_name: 'Arthur',
    last_name: 'Delcourt',
    specialty: 'Tech & Data',
    region: 'Hauts-de-France',
    score: 81,
    bio: "Arthur intervient sur des recrutements tech et data avec une approche tres structuree du brief, du niveau technique attendu et de la capacite reelle des candidats a s integrer dans une roadmap produit ou plateforme."
  },
  {
    email: 'camille.bernard@rivyr.test',
    first_name: 'Camille',
    last_name: 'Bernard',
    specialty: 'Digital & Produit',
    region: 'Ile-de-France',
    score: 78,
    bio: "Camille accompagne ses clients sur des fonctions produit et digitales, avec un vrai soin porte a l evaluation du niveau de structuration, de priorisation et de collaboration transverse."
  },
  {
    email: 'nicolas.morel@rivyr.test',
    first_name: 'Nicolas',
    last_name: 'Morel',
    specialty: 'Supply Chain',
    region: 'Pays de la Loire',
    score: 86,
    bio: "Nicolas est specialise sur les recrutements supply chain, achats et logistique. Il intervient surtout sur des environnements a enjeux operationnels forts, ou la qualite d execution reste decisive."
  },
  {
    email: 'lea.garcia@rivyr.test',
    first_name: 'Lea',
    last_name: 'Garcia',
    specialty: 'Ingenierie',
    region: 'Grand Est',
    score: 76,
    bio: "Lea recrute des chefs de projet, responsables BE et profils techniques experts, avec une forte attention portee a la credibilite metier et a la capacite a faire le lien entre technique et management."
  },
  {
    email: 'hugo.roux@rivyr.test',
    first_name: 'Hugo',
    last_name: 'Roux',
    specialty: 'Maintenance',
    region: 'Normandie',
    score: 73,
    bio: "Hugo intervient principalement sur des fonctions maintenance, fiabilite et travaux neufs. Il est apprecie pour son pragmatisme, sa reactivite et sa capacite a securiser des recrutements penuriques."
  }
].freeze

ALL_FREELANCERS = (PREMIUM_FREELANCERS + STANDARD_FREELANCERS).freeze

CLIENTS_DATA = [
  {
    legal_name: 'Flandres Industrie SAS',
    brand_name: 'Flandres Industrie',
    sector: 'Industrie',
    location: 'Hauts-de-France',
    company_size: '201-500',
    founded_year: 1987,
    revenue: '85 M€',
    ambiance: "Ici, l exigence n est pas un mot de com. Les postes sont exposes, les decisions se prennent vite et les managers sont pleinement responsables de leur perimetre. L ambiance est directe, sobre et orientee resultat. Pas de politique, pas de flou : on sait ce qu on attend de chaque profil des le premier jour.",
    tagline: "Une ETI industrielle qui combine exigence d execution et ambition de transformation.",
    highlights: [
      { title: "Transformation accelee", body: "3 sites industriels restructures en 24 mois avec des gains de productivite mesurables." },
      { title: "Investissement massif", body: "Plan d investissement engage sur la modernisation des lignes et des outils de pilotage." },
      { title: "Management direct", body: "Culture sobre, orientee resultat, ou chaque manager est pleinement responsable de son perimetre." }
    ],
    values: [
      { title: "Exigence utile", body: "Un niveau de jeu eleve, mais toujours aligne avec les realites du terrain et de l execution." },
      { title: "Decisions rapides", body: "Des circuits courts, une gouvernance lisible et une vraie capacite a trancher vite." },
      { title: "Impact industriel", body: "Chaque poste ouvert a une consequence concrete sur la production, la supply ou la transformation." }
    ],
    gallery: ["Site de production modernise", "Comite de direction operations", "Atelier supply & excellence"],
    bio: "ETI industrielle implantee dans les Hauts-de-France, Flandres Industrie conçoit et fabrique des equipements techniques a haute valeur ajoutee pour les secteurs de l energie, de l automobile et de la construction. Avec 350 collaborateurs repartis sur 4 sites, l entreprise est engagee dans une transformation ambitieuse de ses operations. Les recrutements portent sur des profils de direction, production, maintenance et supply chain capables de tenir un niveau d exigence eleve dans un environnement en pleine modernisation."
  },
  {
    legal_name: 'Nord Logistics Group SAS',
    brand_name: 'Nord Logistics Group',
    sector: 'Logistique',
    location: 'Hauts-de-France',
    company_size: '500+',
    founded_year: 1998,
    revenue: '220 M€',
    ambiance: "Le rythme est soutenu et les equipes sont habituees a travailler sous contrainte. La culture du debrief est reelle : on analyse, on ajuste, on repart. Les managers qui s epanouissent ici sont ceux qui aiment le terrain, la mesure et la progression collective.",
    tagline: "Un groupe logistique multi-sites qui recrute des managers capables de piloter la performance terrain.",
    highlights: [
      { title: "Reseau multi-sites", body: "12 plateformes logistiques en France et en Belgique avec des flux nationaux et europeens." },
      { title: "Amelioration continue", body: "Culture du debrief et du management terrain ancree a tous les niveaux de l organisation." },
      { title: "Croissance solide", body: "Contrats grands comptes multi-annuels qui garantissent une activite stable et en expansion." }
    ],
    values: [
      { title: "Performance terrain", body: "Les resultats se mesurent au quotidien, avec des indicateurs clairs et une culture du debrief." },
      { title: "Fiabilite operationnelle", body: "La promesse client repose sur la regularite d execution. Ici, la rigueur n est pas optionnelle." },
      { title: "Management de proximite", body: "Les managers de terrain sont des relais essentiels. Ils sont formes, accompagnes et valorises." }
    ],
    gallery: ["Plateforme logistique Nord", "Equipe transport & quai", "Salle de pilotage flux"],
    bio: "Groupe logistique multi-sites intervenant sur des flux nationaux et europeens depuis plus de 20 ans. Dans un contexte de structuration et d exigence operationnelle forte, Nord Logistics Group recherche des managers et experts capables de piloter la performance terrain, d animer des equipes importantes et de structurer les processus sur des sites a fort volume."
  },
  {
    legal_name: 'BelgoTech Solutions SA',
    brand_name: 'BelgoTech Solutions',
    sector: 'Tech',
    location: 'Belgique',
    company_size: '51-200',
    founded_year: 2014,
    revenue: '18 M€',
    ambiance: "L ambiance est celle d une boite qui construit. Les process existent mais ne figent pas. On teste, on itere, on documente. Les profils qui s integrent bien sont curieux, directs et a l aise avec l incertitude. La croissance est rapide, les responsabilites aussi.",
    tagline: "Une scale-up technologique qui recrute des profils produit, data et management pour accelerer.",
    highlights: [
      { title: "Croissance rapide", body: "+40% en 2 ans avec un modele SaaS recurrent et un pipeline client solide." },
      { title: "Squads autonomes", body: "Organisation produit en equipes independantes avec un fort niveau de responsabilite." },
      { title: "Expansion France", body: "Ambition claire d ouverture du marche francais avec des recrutements strategiques." }
    ],
    values: [
      { title: "Produit avant tout", body: "La valeur delivree a l utilisateur est le critere central de toute decision." },
      { title: "Autonomie responsable", body: "Les equipes ont de la latitude. En contrepartie, les engagements sont tenus." },
      { title: "Culture de la donnee", body: "Chaque hypothese est testee, chaque decision est etayee par des metriques." }
    ],
    gallery: ["Open space Bruxelles", "Retro produit Q1", "Demo Day interne"],
    bio: "Societe technologique en forte croissance implantee en Belgique, intervenant sur des solutions metiers SaaS a haute valeur ajoutee pour les secteurs RH, finance et operations. BelgoTech Solutions recrute des profils produit, tech, data et management capables d evoluer dans un environnement scale-up avec un haut niveau d autonomie et une culture forte de l iteration rapide."
  },
  {
    legal_name: 'Artois Conseil & Transformation SAS',
    brand_name: 'Artois Conseil & Transformation',
    sector: 'Conseil',
    location: 'Hauts-de-France',
    company_size: '11-50',
    founded_year: 2005,
    revenue: '6 M€',
    ambiance: "Ambiance stimulante, sans hierarchie pesante. Les consultants travaillent en autonomie sur des dossiers complexes et s appuient sur une equipe solide pour challenger leurs approches. La liberte est reelle, la rigueur aussi. On attend des profils qui assument leurs positions.",
    tagline: "Un cabinet de conseil exigeant qui recrute des profils seniors credibles face aux dirigeants.",
    highlights: [
      { title: "Interlocuteurs dirigeants", body: "Interventions exclusivement aupres de DG, DAF et membres de comite de direction." },
      { title: "Equipe 100% operationnelle", body: "30 consultants tous issus du terrain, avec un parcours en entreprise avant le conseil." },
      { title: "Conseil engage", body: "Pas de livrables sans mise en oeuvre. Chaque recommandation est portee jusqu au resultat." }
    ],
    values: [
      { title: "Credibilite avant l image", body: "Ici, la valeur d un consultant se mesure a sa capacite a parler vrai face a un dirigeant." },
      { title: "Engagement de resultat", body: "Pas de recommandation sans plan d execution. Le conseil est operationnel ou il n est pas." },
      { title: "Equipe soudee", body: "La cohesion interne est un actif strategique. L ambiance est directe, stimulante et sans politique." }
    ],
    gallery: ["Seminaire equipe conseil", "Atelier client dirigeant", "Restitution comite executif"],
    bio: "Cabinet de conseil specialise dans la transformation d organisations, accompagnant des PME et ETI sur des enjeux de strategie, de reorganisation et de performance. Les recrutements portent sur des profils seniors, autonomes, credibles face a des interlocuteurs de haut niveau, avec un vrai parcours operationnel et la capacite a s engager sur des resultats mesurables."
  },
  {
    legal_name: 'Hexa Retail Performance SAS',
    brand_name: 'Hexa Retail Performance',
    sector: 'Distribution',
    location: 'Ile-de-France',
    company_size: '201-500',
    founded_year: 1993,
    revenue: '130 M€',
    ambiance: "L entreprise est en mouvement. Le nouveau CODIR impulse un changement de rythme et de culture. Ceux qui arrivent maintenant ont une vraie capacite d influence. L ambiance est energique, les attentes sont claires et les profils moteurs trouvent rapidement leur place.",
    tagline: "Un acteur de la distribution qui reorganise son management pour retrouver de la performance.",
    highlights: [
      { title: "Refonte operationnelle", body: "80 points de vente en cours de transformation avec un nouveau modele de management." },
      { title: "Nouveau CODIR", body: "Comite de direction renforce avec une ambition de performance commerciale claire." },
      { title: "Profils qui comptent", body: "Les managers recrutes ont un impact direct et visible sur les resultats du reseau." }
    ],
    values: [
      { title: "Commerce au centre", body: "La performance commerciale est la raison d etre de chaque poste. Elle est pilotee, analysee et recompensee." },
      { title: "Transformation concrete", body: "Le changement est engage. Les profils qui rejoignent l entreprise en sont les acteurs directs." },
      { title: "Equipes responsabilisees", body: "La delegation est reelle. Les managers de terrain ont une vraie latitude de decision." }
    ],
    gallery: ["Concept store modernise", "Reunion performance reseau", "Formation managers terrain"],
    bio: "Acteur de la distribution implante en Ile-de-France et en region, Hexa Retail Performance est en phase d optimisation profonde de son organisation commerciale et operationnelle. L entreprise recrute des profils de direction commerciale, operations et transformation capables de porter une ambition de changement dans un contexte de forte pression sur les resultats."
  },
  {
    legal_name: 'Cap Avenir Energie SAS',
    brand_name: 'Cap Avenir Energie',
    sector: 'Energie',
    location: 'Pays de la Loire',
    company_size: '51-200',
    founded_year: 2010,
    revenue: '42 M€',
    ambiance: "Ambiance entrepreneuriale avec une direction accessible et impliquee. Les decisions se prennent vite, les projets sont concrets et les contributeurs sont reconnus. On valorise les profils qui prennent des initiatives et qui assument la complexite sans attendre qu on leur trace le chemin.",
    tagline: "Une entreprise energetique en croissance qui structure ses equipes pour passer a l echelle.",
    highlights: [
      { title: "Portefeuille en expansion", body: "Projets ENR en forte croissance avec un pipeline securise sur les 3 prochaines annees." },
      { title: "Vision a 5 ans", body: "Direction recemment renforcee avec une feuille de route claire et des objectifs ambitieux." },
      { title: "Culture entrepreneuriale", body: "Prise de responsabilite rapide, autonomie reelle, et impact concret sur les projets livres." }
    ],
    values: [
      { title: "Impact energetique", body: "Chaque projet contribue concretement a la transition. L impact est une realite operationnelle." },
      { title: "Agilite et vitesse", body: "Dans un marche en pleine mutation, les profils qui s adaptent vite et decidient avec partialite ont un vrai avantage." },
      { title: "Ambition partagee", body: "Les collaborateurs construisent quelque chose. Il y a une vraie fierté collective autour des projets livres." }
    ],
    gallery: ["Parc solaire en construction", "Equipe projet terrain", "Reunion strategie direction"],
    bio: "Entreprise du secteur energie engagee dans une dynamique de croissance soutenue et de structuration de ses operations. Cap Avenir Energie intervient sur des projets de production et de distribution d energie renouvelable. Les recrutements portent sur des fonctions techniques, de pilotage de projets et de management capables d evoluer dans un environnement exigeant et en pleine acceleration."
  },
  {
    legal_name: 'Littoral Agro Solutions SAS',
    brand_name: 'Littoral Agro Solutions',
    sector: 'Agroalimentaire',
    location: 'Bretagne',
    company_size: '201-500',
    founded_year: 1979,
    revenue: '95 M€',
    ambiance: "L ambiance est serieuse, technique et ancrée dans le concret. Les equipes sont stables, les process matures et les standards eleves. Les profils qui s y plaisent sont ceux qui aiment la profondeur metier, le travail bien fait et un environnement ou la competence est le premier critere de reconnaissance.",
    tagline: "Un industriel agroalimentaire reconnu qui recrute des experts production, qualite et supply.",
    highlights: [
      { title: "Qualite certifiee", body: "Certifications internationales sur toute la chaine de production, maintenues avec rigueur." },
      { title: "Lignes modernisees", body: "Investissements reguliers dans les equipements et l automatisation des processus." },
      { title: "Exigence technique", body: "Management de terrain solide dans un environnement ou la precision fait la difference." }
    ],
    values: [
      { title: "Qualite non negociable", body: "Les standards sont eleves et tenus. La qualite n est pas un objectif, c est le point de depart." },
      { title: "Efficacite industrielle", body: "La performance des lignes est une priorite quotidienne. Chaque arret non programme est analyse et traite." },
      { title: "Ancrage territorial", body: "L entreprise est implantee en Bretagne depuis 30 ans. Elle est un employeur de reference dans la region." }
    ],
    gallery: ["Ligne de production automatisee", "Controle qualite laboratoire", "Equipe maintenance site"],
    bio: "Societe agroalimentaire bretonne reconnue pour son exigence qualite et son efficacite industrielle, Littoral Agro Solutions emploie 280 collaborateurs sur 2 sites de production. L entreprise recrute des responsables de production, qualite, maintenance et supply chain capables de tenir des standards industriels eleves dans un environnement en modernisation continue."
  },
  {
    legal_name: 'Euronextia Services SAS',
    brand_name: 'Euronextia Services',
    sector: 'Services',
    location: 'Ile-de-France',
    company_size: '51-200',
    founded_year: 2008,
    revenue: '28 M€',
    ambiance: "Ambiance collaborative et orientee client. Les equipes sont soudees, les interactions frequentes et la culture du feedback bien installee. On progresse vite si on est proactif. Les profils autonomes qui cherchent a construire quelque chose de durable trouvent ici un terrain favorable.",
    tagline: "Une entreprise de services B2B en croissance qui renforce ses equipes de direction.",
    highlights: [
      { title: "Retention client elevee", body: "+90% de retention sur 3 ans, signe d une qualite de service qui se mesure concretement." },
      { title: "Nouveaux segments", body: "Expansion sur des marches B2B a fort potentiel avec des ressources dediees." },
      { title: "Responsabilites rapides", body: "Organisation horizontale ou les profils moteurs acced ent vite a des perimetres larges." }
    ],
    values: [
      { title: "Client au centre", body: "La qualite de service est un differenciateur concret. Chaque equipe est orientee satisfaction et retention." },
      { title: "Initiative valorisee", body: "Les profils qui proposent, testent et assument leurs decisions progressent vite." },
      { title: "Croissance collective", body: "L entreprise grandit. Les collaborateurs qui la construisent grandissent avec elle." }
    ],
    gallery: ["Espace de travail collaboratif", "Reunion client strategique", "Workshop equipe commerciale"],
    bio: "Entreprise de services B2B en croissance implantee en Ile-de-France, Euronextia Services accompagne ses clients sur des enjeux de performance commerciale, de pilotage RH et de transformation organisationnelle. L entreprise renforce ses equipes avec des profils commerciaux, RH et direction de pole capables de combiner expertise metier et sens du business."
  },
  {
    legal_name: 'Wallonie Engineering SA',
    brand_name: 'Wallonie Engineering',
    sector: 'Ingenierie',
    location: 'Belgique',
    company_size: '51-200',
    founded_year: 1991,
    revenue: '55 M€',
    ambiance: "Ambiance rigoureuse et exigeante, portee par une culture de l excellence technique. Les equipes sont pluridisciplinaires et habituees a travailler sur des dossiers complexes. La reconnaissance passe par la qualite du travail produit. Peu de politique, beaucoup de substance.",
    tagline: "Un bureau d ingenierie de reference qui recrute des experts techniques et chefs de projet.",
    highlights: [
      { title: "Projets d envergure", body: "Mandats complexes en infrastructure, energie et industrie avec des donneurs d ordre de premier plan." },
      { title: "Equipes expertes", body: "Profils pluridisciplinaires avec un niveau de technicite eleve et une culture de la rigueur." },
      { title: "Partenaires de reference", body: "Collaboration reguliere avec des acteurs publics et prives sur des dossiers strategiques." }
    ],
    values: [
      { title: "Excellence technique", body: "La qualite des livrables est la signature de l entreprise. Elle est exigee et reconnue." },
      { title: "Complexite assumee", body: "Les projets sont ambitieux. Les profils qui reussissent ici ont le gout des problemes difficiles." },
      { title: "Collaboration multidisciplinaire", body: "Les projets mobilisent des expertises variees. La capacite a travailler en transversal est cle." }
    ],
    gallery: ["Chantier infrastructure majeur", "Reunion bureau d etudes", "Revue technique projet"],
    bio: "Bureau d ingenierie et de gestion de projets techniques de reference en Belgique, Wallonie Engineering intervient sur des dossiers a forte technicite dans les secteurs de l infrastructure, de l energie et de l industrie. L entreprise recrute des chefs de projet, experts techniques et responsables de BU capables de piloter des missions complexes avec rigueur et autonomie."
  },
  {
    legal_name: 'Seine Corporate Finance SAS',
    brand_name: 'Seine Corporate Finance',
    sector: 'Finance',
    location: 'Ile-de-France',
    company_size: '11-50',
    founded_year: 2003,
    revenue: '9 M€',
    ambiance: "Ambiance confidentielle, professionnelle et tres axee sur la qualite des livrables. Les interactions sont directes et les attentes elevees. On travaille avec des interlocuteurs seniors, dans des contextes sensibles. Les profils qui s integrent bien sont ceux qui ont une vraie maturite relationnelle.",
    tagline: "Une structure finance d entreprise a taille humaine qui recrute des profils seniors exigeants.",
    highlights: [
      { title: "Mandats exclusifs", body: "Positionnement haut de gamme sur des operations financieres complexes a fort enjeu." },
      { title: "Equipe de reference", body: "25 professionnels issus de grands groupes et cabinets, avec des parcours solides." },
      { title: "Chaque profil compte", body: "Structure a taille humaine ou la contribution individuelle est visible et reconnue." }
    ],
    values: [
      { title: "Expertise avant tout", body: "La valeur se construit sur la profondeur technique et la capacite a produire des analyses qui changent les decisions." },
      { title: "Confidentialite absolue", body: "Les mandats sont sensibles. La discretion est une competence autant qu une valeur." },
      { title: "Posture senior", body: "Les interlocuteurs sont des dirigeants et des investisseurs. La credibilite se construit des le premier echange." }
    ],
    gallery: ["Salle de negociation", "Due diligence en cours", "Closing d operation"],
    bio: "Structure a taille humaine specialisee en finance d entreprise, pilotage de performance et accompagnement de dirigeants sur des operations strategiques. Seine Corporate Finance recrute des profils seniors techniquement solides, capables d incarner une posture de conseil et de s engager sur des resultats concrets dans des contextes de forte pression et de confidentialite."
  }
].freeze

CLIENT_CONTACTS_DATA = [
  { client_legal_name: 'Flandres Industrie SAS', first_name: 'Marion', last_name: 'Lefebvre', job_title: 'Directrice RH' },
  { client_legal_name: 'Nord Logistics Group SAS', first_name: 'Paul', last_name: 'Dufour', job_title: 'Directeur des Operations' },
  { client_legal_name: 'BelgoTech Solutions SA', first_name: 'Elise', last_name: 'Vanhaecke', job_title: 'Head of Talent' },
  { client_legal_name: 'Artois Conseil & Transformation SAS', first_name: 'Julien', last_name: 'Carpentier', job_title: 'Associe' },
  { client_legal_name: 'Hexa Retail Performance SAS', first_name: 'Sonia', last_name: 'Lambert', job_title: 'DRH' },
  { client_legal_name: 'Cap Avenir Energie SAS', first_name: 'Benoit', last_name: 'Rousseau', job_title: 'Directeur General' },
  { client_legal_name: 'Littoral Agro Solutions SAS', first_name: 'Celine', last_name: 'Morin', job_title: 'Responsable Recrutement' },
  { client_legal_name: 'Euronextia Services SAS', first_name: 'David', last_name: 'Perrin', job_title: 'Directeur de Pole' },
  { client_legal_name: 'Wallonie Engineering SA', first_name: 'Aurelie', last_name: 'Masson', job_title: 'HR Manager' },
  { client_legal_name: 'Seine Corporate Finance SAS', first_name: 'Mathieu', last_name: 'Blanc', job_title: 'Partner' }
].freeze

MISSIONS_DATA = [
  { reference: 'MIS-2026-001', client_legal_name: 'Flandres Industrie SAS', specialty: 'Industrie', title: 'Directeur de Site', priority: 'critical' },
  { reference: 'MIS-2026-002', client_legal_name: 'Nord Logistics Group SAS', specialty: 'Supply Chain', title: 'Responsable Supply Chain Groupe', priority: 'high' },
  { reference: 'MIS-2026-003', client_legal_name: 'BelgoTech Solutions SA', specialty: 'Tech & Data', title: 'CTO', priority: 'critical' },
  { reference: 'MIS-2026-004', client_legal_name: 'Artois Conseil & Transformation SAS', specialty: 'Direction Generale', title: 'Directeur de Business Unit', priority: 'high' },
  { reference: 'MIS-2026-005', client_legal_name: 'Hexa Retail Performance SAS', specialty: 'Commercial', title: 'Directeur Commercial', priority: 'critical' },
  { reference: 'MIS-2026-006', client_legal_name: 'Cap Avenir Energie SAS', specialty: 'Ingenierie', title: 'Chef de Projet Senior', priority: 'high' },
  { reference: 'MIS-2026-007', client_legal_name: 'Littoral Agro Solutions SAS', specialty: 'Maintenance', title: 'Responsable Maintenance', priority: 'high' },
  { reference: 'MIS-2026-008', client_legal_name: 'Euronextia Services SAS', specialty: 'Ressources Humaines', title: 'Responsable RH', priority: 'medium' },
  { reference: 'MIS-2026-009', client_legal_name: 'Wallonie Engineering SA', specialty: 'Ingenierie', title: 'Responsable Bureau d Etudes', priority: 'high' },
  { reference: 'MIS-2026-010', client_legal_name: 'Seine Corporate Finance SAS', specialty: 'Finance', title: 'DAF', priority: 'critical' },
  { reference: 'MIS-2026-011', client_legal_name: 'Flandres Industrie SAS', specialty: 'Maintenance', title: 'Ingenieur Fiabilite', priority: 'medium' },
  { reference: 'MIS-2026-012', client_legal_name: 'Nord Logistics Group SAS', specialty: 'Commercial', title: 'Key Account Director', priority: 'high' },
  { reference: 'MIS-2026-013', client_legal_name: 'BelgoTech Solutions SA', specialty: 'Digital & Produit', title: 'Head of Product', priority: 'high' },
  { reference: 'MIS-2026-014', client_legal_name: 'Artois Conseil & Transformation SAS', specialty: 'Commercial', title: 'Business Developer Senior', priority: 'medium' },
  { reference: 'MIS-2026-015', client_legal_name: 'Hexa Retail Performance SAS', specialty: 'Direction Generale', title: 'COO', priority: 'critical' },
  { reference: 'MIS-2026-016', client_legal_name: 'Cap Avenir Energie SAS', specialty: 'Industrie', title: 'Responsable Production', priority: 'medium' },
  { reference: 'MIS-2026-017', client_legal_name: 'Littoral Agro Solutions SAS', specialty: 'Supply Chain', title: 'Responsable Logistique', priority: 'medium' },
  { reference: 'MIS-2026-018', client_legal_name: 'Euronextia Services SAS', specialty: 'Commercial', title: 'Head of Sales', priority: 'high' },
  { reference: 'MIS-2026-019', client_legal_name: 'Wallonie Engineering SA', specialty: 'Direction Generale', title: 'Directeur de Business Unit', priority: 'high' },
  { reference: 'MIS-2026-020', client_legal_name: 'Seine Corporate Finance SAS', specialty: 'Juridique', title: 'Responsable Juridique', priority: 'medium' },

  # 4 missions volontairement alignees avec le profil de Claire Dumont
  { reference: 'MIS-2026-021', client_legal_name: 'Flandres Industrie SAS', specialty: 'Direction Generale', title: 'Directeur General Adjoint', priority: 'critical', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 40 },
  { reference: 'MIS-2026-022', client_legal_name: 'Nord Logistics Group SAS', specialty: 'Direction Generale', title: 'Directeur des Operations Groupe', priority: 'high', status: 'open', origin_type: 'partner', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 18 },
  { reference: 'MIS-2026-023', client_legal_name: 'Artois Conseil & Transformation SAS', specialty: 'Direction Generale', title: 'Directeur Transformation', priority: 'medium', status: 'open', origin_type: 'freelancer', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 12 },
  { reference: 'MIS-2026-024', client_legal_name: 'Flandres Industrie SAS', specialty: 'Direction Generale', title: 'Directeur de Business Unit Industrie', priority: 'critical', status: 'open', origin_type: 'partner', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 5 },

  # Missions supplementaires middle / top management
  { reference: 'MIS-2026-025', client_legal_name: 'Hexa Retail Performance SAS', specialty: 'Marketing', title: 'Head of Growth', priority: 'high', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 30 },
  { reference: 'MIS-2026-026', client_legal_name: 'BelgoTech Solutions SA', specialty: 'Digital & Produit', title: 'Chief Product Officer', priority: 'critical', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 27 },
  { reference: 'MIS-2026-027', client_legal_name: 'Littoral Agro Solutions SAS', specialty: 'Industrie', title: 'Directeur Performance Industrielle', priority: 'high', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 24 },
  { reference: 'MIS-2026-028', client_legal_name: 'Seine Corporate Finance SAS', specialty: 'Finance', title: 'Responsable M&A', priority: 'high', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 21 },
  { reference: 'MIS-2026-029', client_legal_name: 'Euronextia Services SAS', specialty: 'Ressources Humaines', title: 'DRH Groupe', priority: 'critical', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 19 },
  { reference: 'MIS-2026-030', client_legal_name: 'Cap Avenir Energie SAS', specialty: 'Supply Chain', title: 'Directeur Supply Chain Europe', priority: 'critical', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 16 },
  { reference: 'MIS-2026-031', client_legal_name: 'Wallonie Engineering SA', specialty: 'Ingenierie', title: 'Directeur Projets Strategiques', priority: 'high', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 14 },
  { reference: 'MIS-2026-032', client_legal_name: 'Nord Logistics Group SAS', specialty: 'Commercial', title: 'Directeur Grands Comptes', priority: 'high', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 11 },

  # 4 missions assignees a Claire Dumont par Rivyr
  { reference: 'MIS-2026-033', client_legal_name: 'Seine Corporate Finance SAS', specialty: 'Direction Generale', title: 'Directeur General', priority: 'critical', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'claire.dumont@rivyr.test', opened_days_ago: 35 },
  { reference: 'MIS-2026-034', client_legal_name: 'Artois Conseil & Transformation SAS', specialty: 'Direction Generale', title: 'Directeur Associe', priority: 'high', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'claire.dumont@rivyr.test', opened_days_ago: 22 },
  { reference: 'MIS-2026-035', client_legal_name: 'Hexa Retail Performance SAS', specialty: 'Direction Generale', title: 'CEO France', priority: 'critical', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'claire.dumont@rivyr.test', opened_days_ago: 14 },
  { reference: 'MIS-2026-036', client_legal_name: 'Euronextia Services SAS', specialty: 'Direction Generale', title: 'Directeur de Pole Senior', priority: 'high', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'claire.dumont@rivyr.test', opened_days_ago: 7 }
].freeze

PLACEMENTS_DATA = [
  { mission_reference: 'MIS-2026-001', candidate_index: 0, annual_salary_cents: 13_000_000, fee_rate: 0.22, status: 'paid' },
  { mission_reference: 'MIS-2026-003', candidate_index: 1, annual_salary_cents: 14_500_000, fee_rate: 0.23, status: 'validated' },
  { mission_reference: 'MIS-2026-005', candidate_index: 2, annual_salary_cents: 12_000_000, fee_rate: 0.20, status: 'invoiced' },
  { mission_reference: 'MIS-2026-010', candidate_index: 3, annual_salary_cents: 11_000_000, fee_rate: 0.21, status: 'paid' },
  { mission_reference: 'MIS-2026-015', candidate_index: 4, annual_salary_cents: 16_000_000, fee_rate: 0.25, status: 'pending_guarantee' }
].freeze

MISSION_CONTEXT_TEMPLATES = [
  "Le client ouvre ce recrutement pour accelerer une phase de structuration et fiabiliser les decisions operationnelles sur son perimetre.",
  "Le poste s inscrit dans un moment cle de transformation, avec un besoin de leadership visible et de capacite a embarquer des equipes multisites.",
  "Cette mission est directement liee a un enjeu de croissance rentable, avec une attente forte sur la qualite d execution des 100 premiers jours.",
  "Le recrutement est strategique: la personne retenue devra clarifier les priorites, reprendre la maitrise de la performance et installer un cadre solide."
].freeze

MISSION_CHALLENGE_TEMPLATES = [
  "L objectif est d obtenir un impact mesurable rapidement, sans phase d integration trop longue.",
  "Le client attend une posture de decideur, capable de gerer la pression et de faire converger des parties prenantes exigeantes.",
  "Le role demande une vraie maturite relationnelle et une capacite a arbitrer dans un contexte parfois ambigu.",
  "Le scope est large et expose, avec un attendu eleve sur la clarte de communication et le sens du resultat."
].freeze

MISSION_ORGANISATION_TEMPLATES = [
  "Le poste reporte au CEO avec management d une equipe transverse produit, tech et business.",
  "Le role est rattache a la Direction Generale avec interaction directe avec le CODIR.",
  "Le poste est au coeur de l organisation, avec coordination de plusieurs responsables de pole.",
  "Le mandat couvre un perimetre multi-equipes avec pilotage budgetaire et priorisation executive."
].freeze

MISSION_WHY_RECRUITMENT_TEMPLATES = [
  [
    "Structurer la fonction sur un perimetre en forte croissance.",
    "Passer d un mode reactif a une execution planifiee.",
    "Securiser le delivery sur les priorites des 12 prochains mois."
  ],
  [
    "Renforcer le leadership managerial sur une equipe en transition.",
    "Installer des rituels de pilotage et de decision plus robustes.",
    "Accompagner la monte en maturite de l organisation."
  ],
  [
    "Gagner en vitesse d execution sans degrader la qualite.",
    "Clarifier le role de chaque partie prenante du process.",
    "Fiabiliser les indicateurs et la lecture de performance."
  ],
  [
    "Preparer une phase de croissance ambitieuse et structurante.",
    "Aligner le terrain operationnel avec la vision direction.",
    "Professionnaliser les interactions entre metier, produit et operations."
  ]
].freeze

MISSION_12M_ENJEUX_TEMPLATES = [
  [ "Construire une equipe solide", "Ameliorer la roadmap et les priorites", "Structurer la discovery et la qualite d execution" ],
  [ "Stabiliser l organisation interne", "Augmenter la performance collective", "Renforcer la predictibilite des resultats" ],
  [ "Accelerer le time-to-value", "Securiser les recrutements critiques", "Fluidifier la collaboration transverse" ],
  [ "Fiabiliser les indicateurs business", "Installer une cadence de delivery durable", "Elever le niveau managerial des equipes" ]
].freeze

COMPENSATION_SUMMARIES = [
  "30 000EUR - 40 000EUR",
  "45 000EUR - 60 000EUR",
  "65 000EUR - 85 000EUR",
  "90 000EUR - 120 000EUR"
].freeze

SEARCH_REQUIREMENT_TEMPLATES = [
  "Experience indispensable sur un poste comparable, avec des resultats concrets et documentables.",
  "Capacite a tenir un role a forte exposition, avec autonomie de decision et sens politique.",
  "Credibilite metier immediate face a des interlocuteurs seniors et des equipes expertes.",
  "Leadership de transformation attendu, avec priorisation claire et execution rigoureuse."
].freeze

SEARCH_PROCESS_TEMPLATES = [
  "Le client privilegie une shortlist courte (3 a 5 profils), argumentee et exploitable en moins de 10 jours.",
  "Le process doit rester fluide: disponibilites rapides, feedbacks structurees et pilotage serre des etapes.",
  "La validation finale se fait sur adequation de posture, capacite a delivrer vite et compatibilite culturelle.",
  "Le niveau d exigence est eleve sur la qualite de qualification amont, pour eviter les presentations hors cible."
].freeze

MISSION_DETAILS_TEMPLATES = [
  [ "Definir la strategie sur son perimetre", "Piloter la roadmap et les arbitrages", "Installer des methodes de travail robustes", "Collaborer avec la direction et les parties prenantes clefs" ],
  [ "Manager une equipe de responsables", "Prioriser les projets a plus fort impact", "Structurer les process internes", "Accompagner la transformation des pratiques" ],
  [ "Assurer le pilotage de la performance", "Coordonner les acteurs metier et support", "Porter une execution exigeante", "Contribuer aux decisions strategiques" ],
  [ "Prendre en main un perimetre sensible", "Creer les conditions d une execution fiable", "Renforcer les standards de qualite", "Animer un collectif pluridisciplinaire" ]
].freeze

MISSION_TIMELINE_TEMPLATES = [
  [ "Kickoff mission sous 48h", "Shortlist attendue sous 12 jours", "3 entretiens maximum", "Decision finale sous 21 jours" ],
  [ "Cadrage client immediat", "Premier lot de profils sous 10 jours", "Feedback client en 72h", "Closing cible avant fin de mois" ],
  [ "Validation du brief semaine 1", "Approche marche semaine 2", "Entretiens semaine 3", "Signature candidate semaine 4" ],
  [ "Mission lancee en urgence", "Shortlist qualitative sous 2 semaines", "Process decisionnaire resserre", "Demarrage candidat rapide" ]
].freeze

MISSION_RESOURCES_TEMPLATES = [
  [ "Job description complete", "Presentation entreprise", "Organigramme cible", "Notes de cadrage Rivyr" ],
  [ "Contexte business detaille", "Enjeux de poste", "Process client", "Elements de remuneration" ],
  [ "Fiche mission validee", "Synthese des risques", "Attendus du hiring manager", "FAQ client" ],
  [ "Pack onboarding mission", "Benchmarks marches", "Points de vigilance", "Materiaux de qualification" ]
].freeze

NICE_TO_HAVE_TEMPLATES = [
  [ "Transformation Lean", "Experience environnement familial", "Capacite a structurer une fonction from scratch" ],
  [ "Exposition groupe multi-sites", "Posture entrepreneuriale", "Aisance en conduite du changement" ],
  [ "Experience scale-up", "Culture produit/data", "Capacite a recruter et faire grandir une equipe" ],
  [ "Pilotage international", "Maitrise environnements complexes", "Communication executive" ]
].freeze

DIFFICULTY_LEVELS = [ "Moyenne", "Elevee", "Tres elevee", "Critique" ].freeze
CLIENT_EXIGENCE_LEVELS = [ "Standard", "Elevee", "Tres elevee", "Premium" ].freeze
PAYMENT_TERMS = [
  "50% shortlist, 50% placement",
  "40% shortlist, 60% placement",
  "100% au placement",
  "30% demarrage, 70% placement"
].freeze

CANDIDATE_NOTES = [
  "Parcours cohérent, bonne densité d'expérience et communication claire. Le candidat présente un bon niveau de maturité professionnelle.",
  "Profil crédible sur des environnements exigeants, avec une posture rassurante et une motivation bien argumentée.",
  "Candidat structuré, à l'aise dans des fonctions à responsabilité, avec une lecture business intéressante et une bonne capacité d'adaptation.",
  "Expérience solide, discours clair, niveau d'énergie bon et motivations alignées avec des contextes de croissance ou de transformation."
].freeze

CANDIDATE_PROFILES = [
  {
    experiences: [
      { title: "Commercial terrain",                   company: "Groupe Nord Distribution", start_year: 2014, start_month: 3,  end_year: 2017, end_month: 6,   skills: [ "Prospection B2B", "Négociation clients" ] },
      { title: "Responsable grands comptes",           company: "Alliance Commerce Sud",     start_year: 2017, start_month: 9,  end_year: 2020, end_month: 12,  skills: [ "Gestion de portefeuille clients", "Négociation grands comptes" ] },
      { title: "Directeur commercial",                 company: "Euromarket Retail",         start_year: 2021, start_month: 1,  end_year: nil,  end_month: nil, skills: [ "Management d'équipe commerciale", "Pilotage de la performance commerciale", "Développement de portefeuille" ] }
    ]
  },
  {
    experiences: [
      { title: "Chargé de recrutement",                company: "Axia Conseil RH",           start_year: 2013, start_month: 6,  end_year: 2016, end_month: 9,   skills: [ "Sourcing", "Acquisition de talents" ] },
      { title: "Responsable RH",                       company: "Optima Services",           start_year: 2016, start_month: 10, end_year: 2020, end_month: 3,   skills: [ "Gestion des relations sociales", "Pilotage de la masse salariale" ] },
      { title: "DRH",                                  company: "Vectalis Groupe",           start_year: 2020, start_month: 4,  end_year: nil,  end_month: nil, skills: [ "Conduite du changement", "Droit social", "Stratégie RH" ] }
    ]
  },
  {
    experiences: [
      { title: "Contrôleur de gestion",                company: "Finax Groupe",              start_year: 2012, start_month: 9,  end_year: 2016, end_month: 6,   skills: [ "Contrôle de gestion", "Reporting financier" ] },
      { title: "Responsable financier",                company: "Meridia Capital",           start_year: 2016, start_month: 7,  end_year: 2019, end_month: 12,  skills: [ "Consolidation comptable", "Pilotage budgétaire" ] },
      { title: "Directeur Administratif et Financier", company: "Scala Industries",          start_year: 2020, start_month: 2,  end_year: nil,  end_month: nil, skills: [ "Analyse de rentabilité", "Stratégie financière", "Gestion de trésorerie" ] }
    ]
  },
  {
    experiences: [
      { title: "Chef de projet marketing",             company: "Media & Co",                start_year: 2015, start_month: 3,  end_year: 2018, end_month: 7,   skills: [ "Marketing digital", "Gestion de campagnes" ] },
      { title: "Responsable marketing",                company: "Brandex Solutions",         start_year: 2018, start_month: 9,  end_year: 2021, end_month: 5,   skills: [ "Stratégie de marque", "Analyse de données" ] },
      { title: "Directeur marketing",                  company: "Lumio Group",               start_year: 2021, start_month: 6,  end_year: nil,  end_month: nil, skills: [ "Lancement de produit", "Direction d'équipe marketing", "Budget marketing" ] }
    ]
  },
  {
    experiences: [
      { title: "Responsable logistique",               company: "Transit Nord",              start_year: 2013, start_month: 4,  end_year: 2017, end_month: 8,   skills: [ "Gestion des flux", "Pilotage fournisseurs" ] },
      { title: "Responsable supply chain",             company: "Logitrans Europe",          start_year: 2017, start_month: 9,  end_year: 2020, end_month: 6,   skills: [ "Optimisation des processus", "Lean management" ] },
      { title: "Directeur des opérations",             company: "Norexia Logistics",         start_year: 2020, start_month: 7,  end_year: nil,  end_month: nil, skills: [ "Management multisites", "Stratégie supply chain", "Budget opérationnel" ] }
    ]
  },
  {
    experiences: [
      { title: "Responsable production",               company: "Méca Industries",           start_year: 2011, start_month: 2,  end_year: 2015, end_month: 9,   skills: [ "Pilotage de la production", "Gestion budgétaire industrielle" ] },
      { title: "Directeur de site",                    company: "Flandres Manufacturing",    start_year: 2015, start_month: 10, end_year: 2019, end_month: 3,   skills: [ "Management d'équipes terrain", "Amélioration continue" ] },
      { title: "Directeur industriel",                 company: "Arctis Process",            start_year: 2019, start_month: 4,  end_year: nil,  end_month: nil, skills: [ "Sécurité et conformité", "Stratégie industrielle", "Transformation lean" ] }
    ]
  },
  {
    experiences: [
      { title: "Chef de projet",                       company: "Ingenia Solutions",         start_year: 2012, start_month: 9,  end_year: 2016, end_month: 6,   skills: [ "Gestion de projet", "Coordination pluridisciplinaire" ] },
      { title: "Responsable bureau d'études",          company: "Techno Engineering",        start_year: 2016, start_month: 7,  end_year: 2020, end_month: 2,   skills: [ "Analyse technique", "Pilotage de budgets projets" ] },
      { title: "Directeur technique",                  company: "Nexion Systems",            start_year: 2020, start_month: 3,  end_year: nil,  end_month: nil, skills: [ "Validation et mise en service", "Innovation technique", "Management d'experts" ] }
    ]
  },
  {
    experiences: [
      { title: "Chargé de développement",              company: "Nexus Partners",            start_year: 2014, start_month: 6,  end_year: 2018, end_month: 4,   skills: [ "Développement commercial", "Analyse de marché" ] },
      { title: "Responsable business development",     company: "Expansion Group",           start_year: 2018, start_month: 5,  end_year: 2021, end_month: 9,   skills: [ "Négociation partenariale", "Élaboration de business plans" ] },
      { title: "Directeur du développement",           company: "Stratelia Conseil",         start_year: 2021, start_month: 10, end_year: nil,  end_month: nil, skills: [ "Structuration d'alliances", "Stratégie de croissance", "Management de partenariats" ] }
    ]
  }
].freeze

CANDIDATE_EDUCATIONS = [
  # Profil 0 — Commercial
  [
    { category: "diploma",       title: "Master Marketing & Ventes",              institution: "IAE Lille",                    start_year: 2011, start_month: 9, end_year: 2013, end_month: 6 },
    { category: "diploma",       title: "Licence Administration des Entreprises", institution: "Université de Lille",          start_year: 2008, start_month: 9, end_year: 2011, end_month: 6 },
    { category: "certification", title: "Certified Sales Professional (CSP)",     institution: "Sales Management Association", start_year: nil,  start_month: nil, end_year: 2018, end_month: 3 },
    { category: "formation",     title: "Négociation grands comptes",             institution: "Mercuri International",        start_year: nil,  start_month: nil, end_year: 2019, end_month: 10 }
  ],
  # Profil 1 — RH
  [
    { category: "diploma",       title: "Master Gestion des Ressources Humaines", institution: "Sciences Po Lille",            start_year: 2010, start_month: 9, end_year: 2012, end_month: 6 },
    { category: "diploma",       title: "Licence Droit Social",                   institution: "Université Paris II",          start_year: 2007, start_month: 9, end_year: 2010, end_month: 6 },
    { category: "certification", title: "SHRM-CP",                                institution: "SHRM",                         start_year: nil,  start_month: nil, end_year: 2017, end_month: 5 },
    { category: "formation",     title: "Leadership et management d'équipe",      institution: "Cegos",                        start_year: nil,  start_month: nil, end_year: 2020, end_month: 2 }
  ],
  # Profil 2 — Finance
  [
    { category: "diploma",       title: "DSCG",                                   institution: "INTEC Paris",                  start_year: 2009, start_month: 9, end_year: 2012, end_month: 6 },
    { category: "diploma",       title: "DCG",                                    institution: "Université Paris-Dauphine",     start_year: 2006, start_month: 9, end_year: 2009, end_month: 6 },
    { category: "certification", title: "Expert-Comptable stagiaire",             institution: "CNEC",                         start_year: nil,  start_month: nil, end_year: 2014, end_month: 11 },
    { category: "formation",     title: "Pilotage financier et tableaux de bord", institution: "EFE Formation",                start_year: nil,  start_month: nil, end_year: 2017, end_month: 4 }
  ],
  # Profil 3 — Marketing
  [
    { category: "diploma",       title: "Master Marketing Digital",               institution: "ESCP Business School",         start_year: 2012, start_month: 9, end_year: 2014, end_month: 6 },
    { category: "diploma",       title: "Bachelor Commerce & Communication",      institution: "Sup de Pub Paris",             start_year: 2009, start_month: 9, end_year: 2012, end_month: 6 },
    { category: "certification", title: "Google Analytics Certification",          institution: "Google",                       start_year: nil,  start_month: nil, end_year: 2020, end_month: 1 },
    { category: "formation",     title: "Stratégie de marque et brand content",   institution: "ADETEM",                       start_year: nil,  start_month: nil, end_year: 2021, end_month: 3 }
  ],
  # Profil 4 — Supply Chain
  [
    { category: "diploma",       title: "Master Supply Chain Management",         institution: "KEDGE Business School",        start_year: 2010, start_month: 9, end_year: 2012, end_month: 6 },
    { category: "diploma",       title: "Licence Logistique et Transport",        institution: "IUT de Nantes",                start_year: 2007, start_month: 9, end_year: 2010, end_month: 6 },
    { category: "certification", title: "APICS CSCP",                             institution: "APICS",                        start_year: nil,  start_month: nil, end_year: 2016, end_month: 6 },
    { category: "formation",     title: "Lean Management appliqué",               institution: "Institut Lean France",         start_year: nil,  start_month: nil, end_year: 2018, end_month: 9 }
  ],
  # Profil 5 — Industrie
  [
    { category: "diploma",       title: "Diplôme d'Ingénieur Génie Industriel",   institution: "Arts et Métiers ParisTech",     start_year: 2006, start_month: 9, end_year: 2009, end_month: 6 },
    { category: "diploma",       title: "BTS Maintenance Industrielle",           institution: "Lycée Pasteur Lille",          start_year: 2004, start_month: 9, end_year: 2006, end_month: 6 },
    { category: "certification", title: "Black Belt Lean Six Sigma",              institution: "Institut de la Qualité",       start_year: nil,  start_month: nil, end_year: 2014, end_month: 4 },
    { category: "formation",     title: "Management de la performance industrielle", institution: "AFNOR Compétences",         start_year: nil,  start_month: nil, end_year: 2019, end_month: 11 }
  ],
  # Profil 6 — Ingénierie
  [
    { category: "diploma",       title: "Diplôme d'Ingénieur Génie Civil",        institution: "École Centrale de Lille",      start_year: 2008, start_month: 9, end_year: 2011, end_month: 6 },
    { category: "diploma",       title: "Classe Préparatoire MPSI",               institution: "Lycée Faidherbe Lille",        start_year: 2006, start_month: 9, end_year: 2008, end_month: 6 },
    { category: "certification", title: "PMP – Project Management Professional",  institution: "PMI",                          start_year: nil,  start_month: nil, end_year: 2015, end_month: 7 },
    { category: "formation",     title: "BIM et maquette numérique",              institution: "CSTB Formation",               start_year: nil,  start_month: nil, end_year: 2021, end_month: 5 }
  ],
  # Profil 7 — Business Development
  [
    { category: "diploma",       title: "MBA Strategy & Business Development",    institution: "HEC Paris",                    start_year: 2011, start_month: 9, end_year: 2013, end_month: 6 },
    { category: "diploma",       title: "Master Économie Internationale",         institution: "Université Paris I Panthéon",  start_year: 2008, start_month: 9, end_year: 2011, end_month: 6 },
    { category: "certification", title: "Certified Business Development Expert",  institution: "BDPA",                         start_year: nil,  start_month: nil, end_year: 2017, end_month: 9 },
    { category: "formation",     title: "Structuration de partenariats stratégiques", institution: "CCI Paris Île-de-France", start_year: nil,  start_month: nil, end_year: 2020, end_month: 6 }
  ]
].freeze

CANDIDATE_LOCATIONS = [
  'Lille', 'Paris', 'Lyon', 'Bordeaux', 'Nantes', 'Strasbourg', 'Rennes',
  'Marseille', 'Toulouse', 'Bruxelles', 'Rouen', 'Amiens', 'Grenoble', 'Montpellier'
].freeze

CANDIDATE_MOBILITY_ZONES = [
  'Lille et métropole', 'Île-de-France', 'Grand Nord (59/62)', 'France entière',
  'Nord et Paris', 'Hauts-de-France', 'Lyon et région Auvergne-Rhône-Alpes',
  'Bordeaux et Nouvelle-Aquitaine', 'Télétravail complet', 'Europe'
].freeze

CANDIDATE_AVAILABILITIES = %w[immediate one_month three_months six_months other].freeze

CANDIDATE_CONTRACT_TYPES = [
  %w[cdi],
  %w[cdi cdd],
  %w[freelance management_transition],
  %w[cdi freelance],
  %w[cdd interim],
  %w[cdi cdd freelance],
  %w[management_transition],
  %w[freelance interim management_transition]
].freeze

CANDIDATE_SALARY_RANGES = [
  '30 – 40k€', '40 – 50k€', '50 – 60k€', '60 – 75k€',
  '75 – 90k€', '90 – 110k€', '> 110k€'
].freeze

CANDIDATE_LANGUAGES = [
  [ { code: "fr", level: "bilingual" }, { code: "en", level: "professional" } ],
  [ { code: "fr", level: "bilingual" }, { code: "en", level: "bilingual" }, { code: "de", level: "partial" } ],
  [ { code: "fr", level: "bilingual" }, { code: "en", level: "professional" }, { code: "es", level: "partial" } ],
  [ { code: "fr", level: "bilingual" }, { code: "en", level: "bilingual" } ],
  [ { code: "fr", level: "bilingual" }, { code: "nl", level: "professional" }, { code: "en", level: "professional" } ],
  [ { code: "fr", level: "bilingual" }, { code: "en", level: "professional" }, { code: "it", level: "partial" } ],
  [ { code: "fr", level: "bilingual" }, { code: "en", level: "bilingual" }, { code: "pt", level: "partial" } ],
  [ { code: "fr", level: "bilingual" }, { code: "ar", level: "bilingual" }, { code: "en", level: "professional" } ]
].freeze

CANDIDATE_STATUSES = ['new', 'qualified', 'presented', 'interviewing', 'placed'].freeze
CANDIDATE_SOURCES = ['linkedin', 'network', 'jobboard', 'referral', 'direct'].freeze
MISSION_ORIGINS = ['rivyr', 'freelancer', 'partner'].freeze
FREELANCER_OPERATIONAL_STATUSES = ['onboarded', 'active', 'paused'].freeze
FREELANCER_AVAILABILITY_STATUSES = ['available', 'partially_available', 'busy'].freeze
CLIENT_OWNERSHIP_TYPES = ['rivyr', 'shared', 'freelancer'].freeze
COMMISSION_RULES = ['70_30', '75_25', '80_20'].freeze

FIRST_NAMES = %w[
  Nicolas Marjory Thomas Claire Sophie Antoine Julie Arthur Camille Louis Emma Hugo
  Lea Sarah Paul Lucie Julien Marion Alexandre Laura Kevin Elodie Romain Ines Victor Alice
  Quentin Adrien Charlotte Benoit Mathilde Samuel Pierre Chloe Manon Aurelien
].freeze

LAST_NAMES = %w[
  Martin Bernard Dubois Thomas Robert Richard Petit Durand Leroy Moreau Simon Laurent
  Michel Garcia David Bertrand Roux Vincent Fournier Morel Girard Andre Lefebvre Mercier
  Dupont Lambert Bonnet Francois Martinez Delcourt Vandenberghe Carpentier Rousseau
].freeze

# --------------------------------------------------
# 3. Helpers
# Helpers simples pour eviter les repetitions et rendre le seed lisible.
# --------------------------------------------------

def upsert_record(model_or_scope, finder_attrs, assign_attrs)
  record = model_or_scope.find_or_initialize_by(finder_attrs)
  record.assign_attributes(assign_attrs)
  record.save!
  record
end

def safe_phone(seed_number)
  "06#{seed_number.to_s.rjust(8, '0')}"
end

def domain_for(name)
  "#{name.parameterize}.fr"
end

def seeded_date(offset_days)
  Date.current - offset_days
end

def commission_ratio(rule)
  case rule
  when '70_30' then 0.70
  when '75_25' then 0.75
  else 0.80
  end
end

def mission_status_for(index)
  ['open', 'in_progress', 'open', 'closed'][index % 4]
end

def mission_type_for(index)
  ['retained', 'exclusive', 'contingency'][index % 3]
end

def ownership_type_for(index)
  CLIENT_OWNERSHIP_TYPES[index % CLIENT_OWNERSHIP_TYPES.size]
end

def mission_brief_for(data, client, index)
  reference_seed = data[:reference].to_s.each_byte.sum
  context = MISSION_CONTEXT_TEMPLATES[reference_seed % MISSION_CONTEXT_TEMPLATES.size]
  challenge = MISSION_CHALLENGE_TEMPLATES[index % MISSION_CHALLENGE_TEMPLATES.size]
  organisation = MISSION_ORGANISATION_TEMPLATES[reference_seed % MISSION_ORGANISATION_TEMPLATES.size]
  why_items = MISSION_WHY_RECRUITMENT_TEMPLATES[index % MISSION_WHY_RECRUITMENT_TEMPLATES.size]
  enjeux_items = MISSION_12M_ENJEUX_TEMPLATES[reference_seed % MISSION_12M_ENJEUX_TEMPLATES.size]
  creation_or_replacement = index.even? ? "Creation de poste" : "Remplacement"
  estimated_revenue_meur = 25 + (reference_seed % 180)
  estimated_headcount = 60 + (reference_seed % 460)
  hierarchy_level =
    if data[:title].to_s.downcase.match?(/directeur|head|chief|ceo|coo|cto|cfo/)
      "Directeur"
    elsif data[:title].to_s.downcase.match?(/responsable|manager/)
      "Manager"
    else
      "Expert"
    end

  [
    "headline=Mission #{data[:title]} pour #{client.brand_name.presence || client.legal_name} (#{client.sector})",
    "context=#{context}",
    "creation_or_replacement=#{creation_or_replacement}",
    "organisation=#{organisation}",
    "business=#{challenge}",
    "client_context=#{client.brand_name.presence || client.legal_name} - #{client.sector} - #{client.company_size}",
    "company_size=#{client.company_size}",
    "company_revenue_meur=#{estimated_revenue_meur}",
    "company_headcount=#{estimated_headcount}",
    "org_position=Le poste reporte directement a la Direction Generale",
    "hierarchy_level=#{hierarchy_level}",
    "why=#{why_items.join(';')}",
    "enjeux=#{enjeux_items.join(';')}"
  ].join("||")
end

def mission_constraints_for(data, client, index)
  title_seed = data[:title].to_s.each_byte.sum
  requirement = SEARCH_REQUIREMENT_TEMPLATES[title_seed % SEARCH_REQUIREMENT_TEMPLATES.size]
  process = SEARCH_PROCESS_TEMPLATES[index % SEARCH_PROCESS_TEMPLATES.size]
  details = MISSION_DETAILS_TEMPLATES[index % MISSION_DETAILS_TEMPLATES.size]
  timeline = MISSION_TIMELINE_TEMPLATES[title_seed % MISSION_TIMELINE_TEMPLATES.size]
  resources = MISSION_RESOURCES_TEMPLATES[index % MISSION_RESOURCES_TEMPLATES.size]
  nice_to_have = NICE_TO_HAVE_TEMPLATES[index % NICE_TO_HAVE_TEMPLATES.size]
  difficulty = DIFFICULTY_LEVELS[title_seed % DIFFICULTY_LEVELS.size]
  exigence = CLIENT_EXIGENCE_LEVELS[index % CLIENT_EXIGENCE_LEVELS.size]
  closing_probability = 58 + (title_seed % 35)
  history_count = 1 + (index % 5)
  max_freelancers = 2 + (index % 2)
  shortlist_deadline_days = 10 + (title_seed % 14)
  autonomy = [ "Cadre resserre", "Autonomie moderee", "Autonomie elevee", "Autonomie totale" ][index % 4]
  payment_terms = PAYMENT_TERMS[index % PAYMENT_TERMS.size]
  must_have = [
    requirement,
    "Experience du secteur #{client.sector}",
    "Niveau hierarchique coherent avec #{data[:title]}",
    "Capacite a piloter dans une organisation #{client.company_size}"
  ]

  [
    "profil=#{requirement}",
    "constraints=Mobilite coherente avec #{client.location};Niveau de remuneration aligne;Disponibilite reelle sous 3 mois",
    "process=#{process}",
    "details=#{details.join(';')}",
    "must_have=#{must_have.join(';')}",
    "nice_to_have=#{nice_to_have.join(';')}",
    "timeline=#{timeline.join(';')}",
    "resources=#{resources.join(';')}",
    "difficulty=#{difficulty}",
    "history_count=#{history_count}",
    "client_relation=#{index.even? ? 'Client historique RIVYR' : 'Nouveau client RIVYR'}",
    "client_exigence=#{exigence}",
    "closing_probability=#{closing_probability}",
    "collab_pilot=Pilotage RIVYR",
    "collab_autonomy=#{autonomy}",
    "collab_max_freelancers=#{max_freelancers}",
    "collab_deadline_days=#{shortlist_deadline_days}",
    "collab_candidate_sharing=Candidats exclusifs",
    "payment_terms=#{payment_terms}"
  ].join("||")
end

def freelancer_performance_snapshot(seed:, score:)
  months = %w[Jan Feb Mar Apr May Jun Jul]
  base = [[(score.to_i / 20.0).round(1), 2.6].max, 4.9].min
  current = months.each_with_index.map do |_, index|
    wave = ((seed + (index * 3)) % 11) / 10.0
    value = base - 0.8 + (index * 0.14) + wave - 0.35
    value.round(1).clamp(2.2, 4.9)
  end
  previous = months.each_with_index.map do |_, index|
    wave = ((seed + (index * 5)) % 9) / 10.0
    value = current[index] - 0.4 + wave - 0.25
    value.round(1).clamp(2.0, 4.6)
  end

  {
    "months" => months,
    "current" => current,
    "previous" => previous
  }
end

# --------------------------------------------------
# 4. Regions
# --------------------------------------------------

puts "Seeding regions..."
REGIONS_DATA.each do |data|
  upsert_record(Region, { name: data[:name] }, options: data[:options])
end
puts "#{Region.count} regions ready."

# --------------------------------------------------
# 5. Specialties
# --------------------------------------------------

puts "Seeding specialties..."
SPECIALTIES_DATA.each do |data|
  upsert_record(Specialty, { name: data[:name] }, options: data[:options])
end
puts "#{Specialty.count} specialties ready."

regions_by_name = Region.all.index_by(&:name)
specialties_by_name = Specialty.all.index_by(&:name)

# --------------------------------------------------
# 6. Utilisateurs et profils freelances
# Les profils RIVYR sont crees ici avec leurs attributs metier.
# --------------------------------------------------

puts "Seeding users and freelancer profiles..."
ALL_FREELANCERS.each_with_index do |data, index|
  user = upsert_record(User, { email: data[:email] }, {
    password: 'password',
    first_name: data[:first_name],
    last_name: data[:last_name],
    phone: safe_phone(index + 1),
    status: 'active',
    role: 'freelance'
  })

  region = regions_by_name.fetch(data[:region])
  specialty = specialties_by_name.fetch(data[:specialty])

  freelancer_attrs = {
    region: region,
    specialty: specialty,
    operational_status: index < 4 ? 'active' : FREELANCER_OPERATIONAL_STATUSES[index % FREELANCER_OPERATIONAL_STATUSES.size],
    availability_status: index < 4 ? 'available' : FREELANCER_AVAILABILITY_STATUSES[index % FREELANCER_AVAILABILITY_STATUSES.size],
    bio: data[:bio],
    linkedin_url: "https://www.linkedin.com/in/#{data[:first_name].parameterize}-#{data[:last_name].parameterize}",
    website_url: "https://www.#{data[:first_name].parameterize}-#{data[:last_name].parameterize}.fr",
    rivyr_score_current: data[:score],
    profile_private: false
  }
  if FreelancerProfile.column_names.include?("performance_snapshot")
    freelancer_attrs[:performance_snapshot] = freelancer_performance_snapshot(seed: index + 1, score: data[:score])
  end

  upsert_record(FreelancerProfile, { user: user }, freelancer_attrs)
end
puts "#{User.count} users ready."
puts "#{FreelancerProfile.count} freelancer profiles ready."

admin_user = upsert_record(User, { email: "admin@rivyr.test" }, {
  password: "password",
  first_name: "Admin",
  last_name: "Rivyr",
  phone: safe_phone(999),
  status: "active",
  role: "admin"
})

# Pool Rivyr: ce profil porte les missions "non attribuees" de la bibliotheque.
library_region = regions_by_name.fetch("Hauts-de-France")
library_specialty = specialties_by_name.fetch("Direction Generale")
library_pool_attrs = {
  region: library_region,
  specialty: library_specialty,
  operational_status: "active",
  availability_status: "available",
  bio: "Profil pool Rivyr pour les missions non attribuees.",
  linkedin_url: "https://www.linkedin.com/company/rivyr",
  website_url: "https://www.rivyr.com",
  rivyr_score_current: 100,
  profile_private: true
}
if FreelancerProfile.column_names.include?("performance_snapshot")
  library_pool_attrs[:performance_snapshot] = freelancer_performance_snapshot(seed: 99, score: 100)
end
library_freelancer_pool = upsert_record(FreelancerProfile, { user: admin_user }, library_pool_attrs)

# --------------------------------------------------
# 7. Clients
# --------------------------------------------------

puts "Seeding clients..."
CLIENTS_DATA.each_with_index do |data, index|
  upsert_record(Client, { legal_name: data[:legal_name] }, {
    ownership_type: ownership_type_for(index),
    brand_name: data[:brand_name],
    sector: data[:sector],
    website_url: "https://www.#{domain_for(data[:brand_name])}",
    location: data[:location],
    company_size: data[:company_size],
    founded_year: data[:founded_year],
    revenue: data[:revenue],
    ambiance: data[:ambiance],
    bio: data[:bio],
    active: true
  })
end
puts "#{Client.count} clients ready."

clients_by_legal_name = Client.all.index_by(&:legal_name)

# --------------------------------------------------
# 8. Highlights clients (pourquoi nous rejoindre)
# --------------------------------------------------

puts "Seeding client highlights..."
CLIENTS_DATA.each do |data|
  client = clients_by_legal_name[data[:legal_name]]
  next unless client && data[:highlights].present?

  data[:highlights].each_with_index do |h, i|
    ClientHighlight.create!(client: client, title: h[:title], body: h[:body], position: i + 1)
  end
end
puts "#{ClientHighlight.count} client highlights ready."

# --------------------------------------------------
# 9. Valeurs clients
# --------------------------------------------------

puts "Seeding client values..."
CLIENTS_DATA.each do |data|
  client = clients_by_legal_name[data[:legal_name]]
  next unless client && data[:values].present?

  data[:values].each_with_index do |v, i|
    ClientValue.create!(client: client, title: v[:title], body: v[:body], position: i + 1)
  end
end
puts "#{ClientValue.count} client values ready."

# --------------------------------------------------
# 10. Contacts clients
# --------------------------------------------------

puts "Seeding client contacts..."
CLIENT_CONTACTS_DATA.each_with_index do |data, index|
  client = clients_by_legal_name.fetch(data[:client_legal_name])
  email = "#{data[:first_name].parameterize}.#{data[:last_name].parameterize}@#{domain_for(client.brand_name)}"

  upsert_record(ClientContact, { client: client, email: email }, {
    first_name: data[:first_name],
    last_name: data[:last_name],
    phone: safe_phone(100 + index),
    job_title: data[:job_title],
    primary_contact: true
  })
end
puts "#{ClientContact.count} client contacts ready."

contacts_by_client_id = ClientContact.all.group_by(&:client_id).transform_values(&:first)

first_contact = ClientContact.order(:id).first
if first_contact
  client_user = upsert_record(User, { email: "client@rivyr.test" }, {
    password: "password",
    first_name: first_contact.first_name,
    last_name: first_contact.last_name,
    phone: first_contact.phone,
    status: "active",
    role: "client"
  })
  first_contact.update!(user: client_user)
end

# --------------------------------------------------
# 9. Missions
# Mission principale + metadata derivee du client et du template.
# --------------------------------------------------

puts "Seeding missions..."
MISSIONS_DATA.each_with_index do |data, index|
  client = clients_by_legal_name.fetch(data[:client_legal_name])
  contact = contacts_by_client_id.fetch(client.id)
  specialty = specialties_by_name.fetch(data[:specialty])
  region = regions_by_name.fetch(client.location)
  assigned_freelancer = User.includes(:freelancer_profile).find_by(email: data[:assigned_freelancer_email])&.freelancer_profile
  matching_freelancer = assigned_freelancer || FreelancerProfile.joins(:specialty).find_by(specialties: { name: data[:specialty] }) || FreelancerProfile.first
  mission_status = data[:status] || mission_status_for(index)
  mission_origin = data[:origin_type] || MISSION_ORIGINS[index % MISSION_ORIGINS.size]
  opened_days_ago = data[:opened_days_ago] || (180 - (index * 5))
  opened_at = seeded_date(opened_days_ago)
  started_days_ago = data.key?(:started_days_ago) ? data[:started_days_ago] : [ opened_days_ago - 10, 1 ].max
  started_at = seeded_date(started_days_ago)
  closed_days_ago = data[:closed_days_ago] || (120 - (index * 3))
  closed_at = mission_status == 'closed' ? seeded_date(closed_days_ago) : nil
  mission_type = data[:mission_type] || mission_type_for(index)
  brief_summary = mission_brief_for(data, client, index)
  search_constraints = mission_constraints_for(data, client, index)

  upsert_record(Mission, { reference: data[:reference] }, {
    region: region,
    freelancer_profile: matching_freelancer,
    mission_type: mission_type,
    title: data[:title],
    status: mission_status,
    client_contact: contact,
    location: client.location,
    contract_signed: true,
    opened_at: opened_at,
    started_at: started_at,
    closed_at: closed_at,
    priority_level: data[:priority],
    brief_summary: brief_summary,
    compensation_summary: COMPENSATION_SUMMARIES[index % COMPENSATION_SUMMARIES.size],
    search_constraints: search_constraints,
    origin_type: mission_origin,
    specialty: specialty
  })
end
puts "#{Mission.count} missions ready."

missions_by_reference = Mission.all.index_by(&:reference)

# --------------------------------------------------
# 10. Candidats
# --------------------------------------------------

puts "Seeding candidates..."
candidates = []

50.times do |index|
  first_name = FIRST_NAMES[index % FIRST_NAMES.size]
  last_name = "#{LAST_NAMES[index % LAST_NAMES.size]}#{index + 1}"
  email = "#{first_name.parameterize}.#{last_name.parameterize}@candidate.rivyr.test"

  profile = CANDIDATE_PROFILES[index % CANDIDATE_PROFILES.size]
  status = CANDIDATE_STATUSES[index % CANDIDATE_STATUSES.size]
  exp_count = case status
  when 'new'          then 1
  when 'qualified'    then 2
  when 'presented'    then 2
  when 'interviewing' then 3
  when 'placed'       then 3
  else 1
  end

  experiences = profile[:experiences].first(exp_count)
  all_skills   = experiences.flat_map { |e| e[:skills] }.uniq

  candidate = upsert_record(Candidate, { email: email }, {
    first_name: first_name,
    last_name: last_name,
    phone: safe_phone(200 + index),
    linkedin_url: "https://www.linkedin.com/in/#{first_name.parameterize}-#{last_name.parameterize}",
    status: status,
    notes: CANDIDATE_NOTES[index % CANDIDATE_NOTES.size],
    source: CANDIDATE_SOURCES[index % CANDIDATE_SOURCES.size],
    job_titles: experiences.map { |e| e[:title] },
    skills: all_skills,
    location: CANDIDATE_LOCATIONS[index % CANDIDATE_LOCATIONS.size],
    mobility_zone:  CANDIDATE_MOBILITY_ZONES[index % CANDIDATE_MOBILITY_ZONES.size],
    availability:   CANDIDATE_AVAILABILITIES[index % CANDIDATE_AVAILABILITIES.size],
    contract_types: CANDIDATE_CONTRACT_TYPES[index % CANDIDATE_CONTRACT_TYPES.size],
    salary_range:   CANDIDATE_SALARY_RANGES[index % CANDIDATE_SALARY_RANGES.size],
    languages:      CANDIDATE_LANGUAGES[index % CANDIDATE_LANGUAGES.size]
  })

  experiences.each_with_index do |exp, pos|
    WorkExperience.find_or_initialize_by(candidate: candidate, title: exp[:title], company: exp[:company]).tap do |we|
      we.assign_attributes(
        start_year:  exp[:start_year],
        start_month: exp[:start_month],
        end_year:    exp[:end_year],
        end_month:   exp[:end_month],
        skills:      exp[:skills],
        position:    pos
      )
      we.save!
    end
  end

  CANDIDATE_EDUCATIONS[index % CANDIDATE_EDUCATIONS.size].each_with_index do |edu, pos|
    Education.find_or_initialize_by(candidate: candidate, title: edu[:title]).tap do |e|
      e.assign_attributes(
        category:    edu[:category],
        institution: edu[:institution],
        start_year:  edu[:start_year],
        start_month: edu[:start_month],
        end_year:    edu[:end_year],
        end_month:   edu[:end_month],
        position:    pos
      )
      e.save!
    end
  end

  # Contributions
  contribution_data = [
    {
      kind:      "ai_response",
      question:  "Selon vous, quelles sont les clés d'un leadership efficace dans un contexte de transformation organisationnelle ?",
      content:   "Pour moi, le leadership en 2025 passe avant tout par la capacité à créer un environnement de confiance. J'ai appris que les équipes performantes ne sont pas celles qu'on contrôle, mais celles qu'on inspire. Dans mon dernier poste, j'ai mis en place des rituels hebdomadaires courts — 15 minutes — pour donner de la visibilité sur les priorités et recueillir les blocages. Le résultat : une réduction de 30% du turnover sur 18 mois.",
      published: true
    },
    {
      kind:      "open_to_opportunity",
      question:  nil,
      content:   "Je suis actuellement à l'écoute d'opportunités dans mon domaine. Fort de mes expériences en management et développement stratégique, je recherche un nouveau challenge à la hauteur de mes ambitions. N'hésitez pas à me contacter pour échanger.",
      published: true
    },
    {
      kind:      "new_experience",
      question:  nil,
      content:   "Je suis ravi d'annoncer que j'ai rejoint une nouvelle structure dans le cadre d'un projet ambitieux. Cette nouvelle étape s'inscrit dans la continuité de mon parcours et me permet d'explorer de nouveaux challenges passionnants.",
      published: true
    },
    {
      kind:      "ai_response",
      question:  "La transformation digitale est-elle avant tout un enjeu technologique ou humain ? Partagez votre expérience.",
      content:   "La transformation digitale des organisations est souvent perçue comme un enjeu technologique. Je pense au contraire que c'est avant tout un enjeu humain. Accompagner les équipes dans le changement, lever les résistances, co-construire de nouveaux modes de travail : voilà le vrai défi. La technologie n'est que l'outil.",
      published: true
    },
    {
      kind:      "new_education",
      question:  nil,
      content:   "Je viens d'obtenir une nouvelle certification dans mon domaine d'expertise. Cette formation m'a permis d'approfondir mes connaissances et d'acquérir de nouvelles compétences directement applicables dans mon quotidien professionnel.",
      published: [ true, false ].sample
    }
  ]

  contribution_data.first([ 1, 2, 3 ].sample).each_with_index do |data, pos|
    published_at = (index + pos + 1).weeks.ago
    Contribution.find_or_initialize_by(candidate: candidate, kind: data[:kind], content: data[:content].first(50)).tap do |c|
      c.assign_attributes(
        question:     data[:question],
        content:      data[:content],
        published:    data[:published],
        published_at: data[:published] ? published_at : nil
      )
      c.save!
    end
  end

  candidates << candidate
end

puts "#{Candidate.count} candidates ready."

first_candidate = Candidate.order(:id).first
if first_candidate
  candidate_user = upsert_record(User, { email: "candidate@rivyr.test" }, {
    password: "password",
    first_name: first_candidate.first_name,
    last_name: first_candidate.last_name,
    phone: first_candidate.phone,
    status: "active",
    role: "candidate"
  })
  first_candidate.update!(user: candidate_user)
end

# --------------------------------------------------
# 11. Placements
# --------------------------------------------------

puts "Seeding placements..."
placements = PLACEMENTS_DATA.map.with_index do |data, index|
  mission = missions_by_reference.fetch(data[:mission_reference])
  candidate = candidates[data[:candidate_index]]
  fee_cents = (data[:annual_salary_cents] * data[:fee_rate]).to_i

  upsert_record(Placement, { mission: mission, candidate: candidate }, {
    hired_at: seeded_date(60 - (index * 7)),
    annual_salary_cents: data[:annual_salary_cents],
    placement_fee_cents: fee_cents,
    status: data[:status],
    notes: "Placement realise sur une fonction a fort enjeu apres un process structure, une shortlist ciblee et une prise de decision rapide du client."
  })
end

puts "#{Placement.count} placements ready."

# --------------------------------------------------
# 12. Factures et notes de suivi
# --------------------------------------------------

puts "Seeding invoices..."
invoices = placements.map.with_index do |placement, index|
  number = "FAC-#{Date.current.year}-#{format('%04d', index + 1)}"

  upsert_record(Invoice, { number: number }, {
    invoice_type: 'client',
    issue_date: placement.hired_at + 5,
    paid_date: index.even? ? placement.hired_at + 20 : nil,
    amount_cents: placement.placement_fee_cents,
    placement: placement,
    status: index.even? ? 'paid' : 'issued'
  })
end
puts "#{Invoice.count} invoices ready."

puts "Seeding invoice notes..."
Invoice.where(invoice_type: "client").limit(6).each_with_index do |invoice, index|
  InvoiceNote.create!(
    invoice: invoice,
    user: admin_user,
    note_type: "follow_up",
    action_required: (index % 3).zero?,
    body: "Relance client ##{index + 1}: appel realise, en attente de retour du service comptable."
  )
end
puts "#{InvoiceNote.count} invoice notes ready."

# --------------------------------------------------
# 13. Commissions et factures freelance
# --------------------------------------------------

puts "Seeding commissions..."
commissions = placements.map.with_index do |placement, index|
  rule = COMMISSION_RULES[index % COMMISSION_RULES.size]
  ratio = commission_ratio(rule)
  freelancer_share = (placement.placement_fee_cents * ratio).to_i
  rivyr_share = placement.placement_fee_cents - freelancer_share

  upsert_record(Commission, { placement: placement }, {
    commission_rule: rule,
    status: index.even? ? 'paid' : 'eligible',
    gross_amount_cents: placement.placement_fee_cents,
    rivyr_share_cents: rivyr_share,
    freelancer_share_cents: freelancer_share,
    client_payment_required: true,
    eligible_for_invoicing_at: placement.hired_at + 3
  })
end
puts "#{Commission.count} commissions ready."

puts "Seeding freelancer invoices..."
placements.each_with_index do |placement, index|
  next unless index < 4
  next unless placement.client_invoice&.status == "paid"
  next if placement.invoices.where(invoice_type: "freelancer").exists?

  Invoice.create!(
    placement: placement,
    invoice_type: "freelancer",
    number: "FAC-FRE-#{Date.current.year}-#{format('%04d', index + 1)}",
    status: "issued",
    issue_date: Date.current - (15 - index),
    amount_cents: placement.commission&.freelancer_share_cents.to_i
  )
end
puts "#{Invoice.where(invoice_type: 'freelancer').count} freelancer invoices ready."

# --------------------------------------------------
# 14. Paiements et demandes de virement
# --------------------------------------------------

puts "Seeding payments..."
placements.each_with_index do |placement, index|
  invoice = invoices[index]
  commission = commissions[index]

  client_payment_ref = "PAY-CLI-#{format('%04d', index + 1)}"
  upsert_record(Payment, { reference: client_payment_ref }, {
    invoice: invoice,
    commission: commission,
    amount_cents: invoice.amount_cents,
    paid_at: invoice.paid_date&.to_time&.change(hour: 10, min: 0),
    payment_type: 'client_payment',
    status: invoice.status == 'paid' ? 'paid' : 'pending'
  })

  freelancer_payment_ref = "PAY-FREE-#{format('%04d', index + 1)}"
  upsert_record(Payment, { reference: freelancer_payment_ref }, {
    invoice: invoice,
    commission: commission,
    amount_cents: commission.freelancer_share_cents,
    paid_at: (invoice.paid_date || Date.current).to_time.change(hour: 15, min: 0),
    payment_type: 'freelancer_payout',
    status: invoice.status == 'paid' ? 'paid' : 'pending'
  })
end
puts "#{Payment.count} payments ready."

puts "Seeding payout requests..."
freelancer_invoice_sample = Invoice.where(invoice_type: "freelancer").first
if freelancer_invoice_sample
  upsert_record(PayoutRequest, {
    user: freelancer_invoice_sample.placement.mission.freelancer_profile.user,
    invoice: freelancer_invoice_sample
  }, {
    amount_cents: freelancer_invoice_sample.amount_cents,
    billing_number: freelancer_invoice_sample.number,
    status: "pending",
    requested_at: Time.current,
    bank_account_label: "Compte principal"
  })
end
puts "#{PayoutRequest.count} payout requests ready."

# --------------------------------------------------
# 15. Dataset de demo finance
# Cas d'usage dedie a Claire Dumont pour la page finance freelance.
# --------------------------------------------------

puts "Seeding dedicated finance demo for Claire Dumont..."

claire_user = User.find_by!(email: "claire.dumont@rivyr.test")
claire_profile = FreelancerProfile.find_by!(user: claire_user)
fallback_profile = FreelancerProfile.where.not(id: claire_profile.id).first

claire_assigned_refs = %w[MIS-2026-033 MIS-2026-034 MIS-2026-035 MIS-2026-036]

if fallback_profile
  Mission.where(freelancer_profile_id: claire_profile.id)
         .where.not(reference: claire_assigned_refs)
         .update_all(freelancer_profile_id: fallback_profile.id)
end

demo_candidates = Candidate.limit(8).to_a
demo_contacts = ClientContact.limit(8).to_a
demo_region = Region.find_by(name: "Hauts-de-France") || Region.first
demo_specialty = Specialty.find_by(name: "Direction Generale") || Specialty.first

demo_rows = [
  # 2 missions en attente de paiement par le client
  { suffix: "A1", title: "CTO de transition", client_invoice_status: "issued", freelancer_share_cents: 4_800_00, rule: "80_20", payout_status: nil, require_action_note: true },
  { suffix: "A2", title: "Head of Ops", client_invoice_status: "issued", freelancer_share_cents: 3_600_00, rule: "75_25", payout_status: nil, require_action_note: false },
  # 2 missions en demande de virement Rivyr
  { suffix: "B1", title: "DAF Groupe", client_invoice_status: "paid", freelancer_share_cents: 4_000_00, rule: "80_20", payout_status: "pending", payout_amount_cents: 1_000_00, require_action_note: false },
  { suffix: "B2", title: "Directeur Commercial", client_invoice_status: "paid", freelancer_share_cents: 5_000_00, rule: "80_20", payout_status: "approved", payout_amount_cents: 2_000_00, require_action_note: false },
  # 2 missions en attente de paiement client
  { suffix: "C1", title: "COO", client_invoice_status: "issued", freelancer_share_cents: 5_600_00, rule: "70_30", payout_status: nil, require_action_note: true },
  { suffix: "C2", title: "Directeur de Site", client_invoice_status: "issued", freelancer_share_cents: 4_200_00, rule: "70_30", payout_status: nil, require_action_note: false },
  # 2 missions en attente de facturation freelance
  { suffix: "D1", title: "VP People", client_invoice_status: "paid", freelancer_share_cents: 3_000_00, rule: "75_25", payout_status: nil, require_action_note: false },
  { suffix: "D2", title: "Responsable Transformation", client_invoice_status: "paid", freelancer_share_cents: 3_000_00, rule: "75_25", payout_status: nil, require_action_note: false }
]

demo_rows.each_with_index do |row, index|
  contact = demo_contacts[index]
  candidate = demo_candidates[index]
  candidate_sources = %w[linkedin jobboard network referral linkedin jobboard network direct]
  candidate_statuses = %w[placed interviewing presented qualified placed interviewing presented qualified]
  candidate.update!(source: candidate_sources[index], status: candidate_statuses[index])
  ratio = commission_ratio(row[:rule])
  gross_amount_cents = (row[:freelancer_share_cents] / ratio).round
  rivyr_share_cents = gross_amount_cents - row[:freelancer_share_cents]
  hired_date = Date.current - (45 - index * 3)
  mission_ref = "MIS-CL-2026-#{format('%02d', index + 1)}"
  mission_seed_data = { reference: mission_ref, title: row[:title] }
  mission_brief = mission_brief_for(mission_seed_data, contact.client, index)
  mission_constraints = mission_constraints_for(mission_seed_data, contact.client, index)

  mission = Mission.create!(
    reference: mission_ref,
    region: demo_region,
    freelancer_profile: claire_profile,
    mission_type: "retained",
    title: row[:title],
    status: "in_progress",
    client_contact: contact,
    location: contact.client.location,
    contract_signed: true,
    opened_at: hired_date - 30,
    started_at: hired_date - 25,
    priority_level: index.even? ? "high" : "critical",
    brief_summary: mission_brief,
    compensation_summary: COMPENSATION_SUMMARIES[index % COMPENSATION_SUMMARIES.size],
    search_constraints: mission_constraints,
    origin_type: "freelancer",
    specialty: demo_specialty
  )

  placement = Placement.create!(
    mission: mission,
    candidate: candidate,
    hired_at: hired_date,
    annual_salary_cents: 12_000_000 + (index * 200_000),
    placement_fee_cents: gross_amount_cents,
    status: row[:client_invoice_status] == "paid" ? "invoiced" : "validated",
    notes: "Placement de demonstration pour pilotage financier freelance."
  )

  client_invoice = Invoice.create!(
    placement: placement,
    invoice_type: "client",
    number: "FAC-CLI-CL-2026-#{format('%02d', index + 1)}",
    status: row[:client_invoice_status],
    issue_date: hired_date + 5,
    paid_date: row[:client_invoice_status] == "paid" ? (hired_date + 18) : nil,
    amount_cents: gross_amount_cents
  )

  Commission.create!(
    placement: placement,
    commission_rule: row[:rule],
    status: row[:client_invoice_status] == "paid" ? "paid" : "eligible",
    gross_amount_cents: gross_amount_cents,
    rivyr_share_cents: rivyr_share_cents,
    freelancer_share_cents: row[:freelancer_share_cents],
    client_payment_required: true,
    eligible_for_invoicing_at: hired_date + 7
  )

  note_templates = [
    "Client contacte: paiement confirme pour fin de mois. Rappel convenu la semaine prochaine pour confirmation de mise en paiement.",
    "Service compta: merci d'ajouter le numero de commande BON-#{format('%04d', 320 + index)} sur la facture.",
    "Echange telephonique avec la DRH: accord sur l'echeance de paiement, validation interne en cours.",
    "Relance email envoyee au client, reponse attendue sous 48h."
  ]

  InvoiceNote.create!(
    invoice: client_invoice,
    user: admin_user,
    note_type: "follow_up",
    action_required: row[:require_action_note],
    body: row[:require_action_note] ? note_templates[index % note_templates.size] : note_templates[(index + 1) % note_templates.size],
    created_at: Time.current - (index + 2).days - index.hours,
    updated_at: Time.current - (index + 2).days - index.hours
  )

  next unless row[:client_invoice_status] == "paid" && row[:payout_status].present?

  freelancer_invoice = Invoice.create!(
    placement: placement,
    invoice_type: "freelancer",
    number: "FAC-FRE-CL-2026-#{format('%02d', index + 1)}",
    status: "issued",
    issue_date: hired_date + 20,
    amount_cents: row[:freelancer_share_cents]
  )

  PayoutRequest.create!(
    user: claire_user,
    invoice: freelancer_invoice,
    amount_cents: row[:payout_amount_cents],
    billing_number: freelancer_invoice.number,
    status: row[:payout_status],
    requested_at: Time.current - (index + 1).days,
    bank_account_label: "Compte principal Claire"
  )
end

claire_wallet_cents = Placement
  .joins(mission: :freelancer_profile)
  .includes(:commission, :client_invoice, freelancer_invoice: :payout_requests)
  .where(freelancer_profiles: { user_id: claire_user.id })
  .sum do |placement|
    next 0 unless placement.client_invoice&.status_paid?

    placement.commission&.freelancer_share_cents.to_i
  end - claire_user.payout_requests.where(status: "paid").sum(:amount_cents) - claire_user.payout_requests.where(status: %w[pending approved]).sum(:amount_cents)

puts "Claire wallet seeded: #{(claire_wallet_cents / 100.0).round(2)} EUR"
puts "Claire demo placements: #{Placement.joins(mission: :freelancer_profile).where(freelancer_profiles: { user_id: claire_user.id }).count}"

puts "============================"
puts "SEED COMPLETED"
puts "============================"
puts "Regions: #{Region.count}"
puts "Specialties: #{Specialty.count}"
puts "Users: #{User.count}"
puts "FreelancerProfiles: #{FreelancerProfile.count}"
puts "Clients: #{Client.count}"
puts "ClientContacts: #{ClientContact.count}"
puts "Missions: #{Mission.count}"
puts "Candidates: #{Candidate.count}"
puts "Placements: #{Placement.count}"
puts "Invoices: #{Invoice.count}"
puts "Commissions: #{Commission.count}"
puts "Payments: #{Payment.count}"
puts "InvoiceNotes: #{InvoiceNote.count}"
puts "PayoutRequests: #{PayoutRequest.count}"
puts "============================"
