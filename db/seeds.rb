# db/seeds.rb
# rails db:seed

require 'faker'

Faker::Config.locale = 'fr'

puts "============================"
puts "RIVYR SEED START"
puts "============================"

# --------------------------------------------------
# Clean database
# --------------------------------------------------

puts "Cleaning database..."

Payment.destroy_all
PayoutRequest.destroy_all
InvoiceNote.destroy_all
Commission.destroy_all
Invoice.destroy_all
Placement.destroy_all
Mission.destroy_all
ClientContact.destroy_all
Client.destroy_all
Candidate.destroy_all
FreelancerProfile.destroy_all
User.destroy_all
Region.destroy_all
Specialty.destroy_all

puts "Database cleaned."

# --------------------------------------------------
# Constants
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
    bio: "ETI industrielle basee dans les Hauts-de-France, specialisee dans la conception et la fabrication d equipements techniques. L entreprise renforce ses equipes de management et recrute regulierement des profils de direction, production, maintenance et supply chain."
  },
  {
    legal_name: 'Nord Logistics Group SAS',
    brand_name: 'Nord Logistics Group',
    sector: 'Logistique',
    location: 'Hauts-de-France',
    company_size: '500+',
    bio: "Groupe logistique multi-sites intervenant sur des flux nationaux et europeens. Dans un contexte de structuration et d exigence operationnelle forte, l entreprise recherche des managers et experts capables de piloter la performance terrain."
  },
  {
    legal_name: 'BelgoTech Solutions SA',
    brand_name: 'BelgoTech Solutions',
    sector: 'Tech',
    location: 'Belgique',
    company_size: '51-200',
    bio: "Societe technologique en croissance implantee en Belgique, intervenant sur des solutions metiers a forte valeur ajoutee. Les recrutements concernent des fonctions produit, tech, data et management."
  },
  {
    legal_name: 'Artois Conseil & Transformation SAS',
    brand_name: 'Artois Conseil & Transformation',
    sector: 'Conseil',
    location: 'Hauts-de-France',
    company_size: '11-50',
    bio: "Cabinet de conseil specialise dans la transformation d organisations, accompagnant des PME, ETI et groupes. L enjeu de recrutement porte sur des profils seniors, autonomes et credibles face a des interlocuteurs de haut niveau."
  },
  {
    legal_name: 'Hexa Retail Performance SAS',
    brand_name: 'Hexa Retail Performance',
    sector: 'Distribution',
    location: 'Ile-de-France',
    company_size: '201-500',
    bio: "Acteur de la distribution en phase d optimisation de son organisation, avec des besoins reguliers sur des fonctions de direction commerciale, operations et transformation."
  },
  {
    legal_name: 'Cap Avenir Energie SAS',
    brand_name: 'Cap Avenir Energie',
    sector: 'Energie',
    location: 'Pays de la Loire',
    company_size: '51-200',
    bio: "Entreprise du secteur energie engagee dans une dynamique de croissance et de structuration. Les recrutements portent sur des fonctions techniques, de pilotage de projets et de management."
  },
  {
    legal_name: 'Littoral Agro Solutions SAS',
    brand_name: 'Littoral Agro Solutions',
    sector: 'Agroalimentaire',
    location: 'Bretagne',
    company_size: '201-500',
    bio: "Societe agroalimentaire reconnue pour son exigence qualite et son efficacite industrielle. Elle recrute des responsables de production, qualite, maintenance et supply chain."
  },
  {
    legal_name: 'Euronextia Services SAS',
    brand_name: 'Euronextia Services',
    sector: 'Services',
    location: 'Ile-de-France',
    company_size: '51-200',
    bio: "Entreprise de services B2B en croissance, cherchant a renforcer ses equipes commerciales, RH et direction de pole avec des profils solides et structurants."
  },
  {
    legal_name: 'Wallonie Engineering SA',
    brand_name: 'Wallonie Engineering',
    sector: 'Ingenierie',
    location: 'Belgique',
    company_size: '51-200',
    bio: "Bureau d ingenierie et de projets techniques intervenant sur des dossiers a forte technicite. L entreprise cible des chefs de projet, experts techniques et responsables de BU."
  },
  {
    legal_name: 'Seine Corporate Finance SAS',
    brand_name: 'Seine Corporate Finance',
    sector: 'Finance',
    location: 'Ile-de-France',
    company_size: '11-50',
    bio: "Structure a taille humaine specialisee en finance d entreprise et pilotage de performance. Elle recherche des profils seniors, techniquement solides et capables d incarner une posture de conseil."
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
  { reference: 'MIS-2026-032', client_legal_name: 'Nord Logistics Group SAS', specialty: 'Commercial', title: 'Directeur Grands Comptes', priority: 'high', status: 'open', origin_type: 'rivyr', assigned_freelancer_email: 'admin@rivyr.test', opened_days_ago: 11 }
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
  "Parcours coherent, bonne densite d experience et communication claire. Le candidat presente un bon niveau de maturite professionnelle.",
  "Profil credible sur des environnements exigeants, avec une posture rassurante et une motivation bien argumentee.",
  "Candidat structure, a l aise dans des fonctions a responsabilite, avec une lecture business interessante et une bonne capacite d adaptation.",
  "Experience solide, discours clair, niveau d energie bon et motivations alignees avec des contextes de croissance ou de transformation."
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
# Helpers
# --------------------------------------------------

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

# --------------------------------------------------
# Regions
# --------------------------------------------------

puts "Seeding regions..."
REGIONS_DATA.each do |data|
  region = Region.find_or_create_by!(name: data[:name])
  region.update!(options: data[:options])
end
puts "#{Region.count} regions ready."

# --------------------------------------------------
# Specialties
# --------------------------------------------------

puts "Seeding specialties..."
SPECIALTIES_DATA.each do |data|
  specialty = Specialty.find_or_create_by!(name: data[:name])
  specialty.update!(options: data[:options])
end
puts "#{Specialty.count} specialties ready."

# --------------------------------------------------
# Users + Freelancer Profiles
# --------------------------------------------------

puts "Seeding users and freelancer profiles..."
ALL_FREELANCERS.each_with_index do |data, index|
  user = User.find_or_create_by!(email: data[:email]) do |u|
    u.password = 'password'
    u.first_name = data[:first_name]
    u.last_name = data[:last_name]
    u.phone = safe_phone(index + 1)
    u.status = 'active'
    u.role = 'freelance'
  end

  user.update!(
    first_name: data[:first_name],
    last_name: data[:last_name],
    phone: user.phone.presence || safe_phone(index + 1),
    status: 'active',
    role: 'freelance'
  )

  region = Region.find_by!(name: data[:region])
  specialty = Specialty.find_by!(name: data[:specialty])

  freelancer = FreelancerProfile.find_or_create_by!(user: user) do |fp|
    fp.region = region
    fp.specialty = specialty
    fp.operational_status = 'active'
    fp.availability_status = 'available'
    fp.bio = data[:bio]
    fp.linkedin_url = "https://www.linkedin.com/in/#{data[:first_name].parameterize}-#{data[:last_name].parameterize}"
    fp.website_url = "https://www.#{data[:first_name].parameterize}-#{data[:last_name].parameterize}.fr"
    fp.rivyr_score_current = data[:score]
    fp.profile_private = false
  end

  freelancer.update!(
    region: region,
    specialty: specialty,
    operational_status: index < 4 ? 'active' : FREELANCER_OPERATIONAL_STATUSES[index % FREELANCER_OPERATIONAL_STATUSES.size],
    availability_status: index < 4 ? 'available' : FREELANCER_AVAILABILITY_STATUSES[index % FREELANCER_AVAILABILITY_STATUSES.size],
    bio: data[:bio],
    linkedin_url: "https://www.linkedin.com/in/#{data[:first_name].parameterize}-#{data[:last_name].parameterize}",
    website_url: "https://www.#{data[:first_name].parameterize}-#{data[:last_name].parameterize}.fr",
    rivyr_score_current: data[:score],
    profile_private: false
  )
end
puts "#{User.count} users ready."
puts "#{FreelancerProfile.count} freelancer profiles ready."

admin_user = User.find_or_create_by!(email: "admin@rivyr.test") do |u|
  u.password = "password"
  u.first_name = "Admin"
  u.last_name = "Rivyr"
  u.phone = safe_phone(999)
  u.status = "active"
  u.role = "admin"
end
admin_user.update!(status: "active", role: "admin")

# Pool Rivyr: ce profil porte les missions "non attribuees" de la bibliotheque.
library_region = Region.find_by!(name: "Hauts-de-France")
library_specialty = Specialty.find_by!(name: "Direction Generale")
library_freelancer_pool = FreelancerProfile.find_or_create_by!(user: admin_user) do |fp|
  fp.region = library_region
  fp.specialty = library_specialty
  fp.operational_status = "active"
  fp.availability_status = "available"
  fp.bio = "Profil pool Rivyr pour les missions non attribuees."
  fp.linkedin_url = "https://www.linkedin.com/company/rivyr"
  fp.website_url = "https://www.rivyr.com"
  fp.rivyr_score_current = 100
  fp.profile_private = true
end
library_freelancer_pool.update!(
  region: library_region,
  specialty: library_specialty,
  operational_status: "active",
  availability_status: "available",
  profile_private: true
)

# --------------------------------------------------
# Clients
# --------------------------------------------------

puts "Seeding clients..."
CLIENTS_DATA.each_with_index do |data, index|
  client = Client.find_or_create_by!(legal_name: data[:legal_name])
  client.update!(
    ownership_type: ownership_type_for(index),
    brand_name: data[:brand_name],
    sector: data[:sector],
    website_url: "https://www.#{domain_for(data[:brand_name])}",
    location: data[:location],
    company_size: data[:company_size],
    bio: data[:bio],
    active: true
  )
end
puts "#{Client.count} clients ready."

# --------------------------------------------------
# Client contacts
# --------------------------------------------------

puts "Seeding client contacts..."
CLIENT_CONTACTS_DATA.each_with_index do |data, index|
  client = Client.find_by!(legal_name: data[:client_legal_name])
  email = "#{data[:first_name].parameterize}.#{data[:last_name].parameterize}@#{domain_for(client.brand_name)}"

  contact = ClientContact.find_or_create_by!(client: client, email: email) do |c|
    c.first_name = data[:first_name]
    c.last_name = data[:last_name]
    c.phone = safe_phone(100 + index)
    c.job_title = data[:job_title]
    c.primary_contact = true
  end

  contact.update!(
    first_name: data[:first_name],
    last_name: data[:last_name],
    phone: safe_phone(100 + index),
    job_title: data[:job_title],
    primary_contact: true
  )
end
puts "#{ClientContact.count} client contacts ready."

first_contact = ClientContact.order(:id).first
if first_contact
  client_user = User.find_or_create_by!(email: "client@rivyr.test") do |u|
    u.password = "password"
    u.first_name = first_contact.first_name
    u.last_name = first_contact.last_name
    u.phone = first_contact.phone
    u.status = "active"
    u.role = "client"
  end
  client_user.update!(status: "active", role: "client")
  first_contact.update!(user: client_user)
end

# --------------------------------------------------
# Missions
# --------------------------------------------------

puts "Seeding missions..."
MISSIONS_DATA.each_with_index do |data, index|
  client = Client.find_by!(legal_name: data[:client_legal_name])
  contact = ClientContact.find_by!(client: client)
  specialty = Specialty.find_by!(name: data[:specialty])
  region = Region.find_by!(name: client.location)
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

  mission = Mission.find_or_create_by!(reference: data[:reference]) do |m|
    m.region = region
    m.freelancer_profile = matching_freelancer
    m.mission_type = mission_type
    m.title = data[:title]
    m.status = mission_status
    m.client_contact = contact
    m.location = client.location
    m.contract_signed = true
    m.opened_at = opened_at
    m.started_at = started_at
    m.closed_at = closed_at
    m.priority_level = data[:priority]
    m.brief_summary = brief_summary
    m.compensation_summary = COMPENSATION_SUMMARIES[index % COMPENSATION_SUMMARIES.size]
    m.search_constraints = search_constraints
    m.origin_type = mission_origin
    m.specialty = specialty
  end

  mission.update!(
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
  )
end
puts "#{Mission.count} missions ready."

# --------------------------------------------------
# Candidates
# --------------------------------------------------

puts "Seeding candidates..."
candidates = []

50.times do |index|
  first_name = FIRST_NAMES[index % FIRST_NAMES.size]
  last_name = "#{LAST_NAMES[index % LAST_NAMES.size]}#{index + 1}"
  email = "#{first_name.parameterize}.#{last_name.parameterize}@candidate.rivyr.test"

  candidate = Candidate.find_or_create_by!(email: email) do |c|
    c.first_name = first_name
    c.last_name = last_name
    c.phone = safe_phone(200 + index)
    c.linkedin_url = "https://www.linkedin.com/in/#{first_name.parameterize}-#{last_name.parameterize}"
    c.status = CANDIDATE_STATUSES[index % CANDIDATE_STATUSES.size]
    c.notes = CANDIDATE_NOTES[index % CANDIDATE_NOTES.size]
    c.source = CANDIDATE_SOURCES[index % CANDIDATE_SOURCES.size]
  end

  candidate.update!(
    first_name: first_name,
    last_name: last_name,
    phone: safe_phone(200 + index),
    linkedin_url: "https://www.linkedin.com/in/#{first_name.parameterize}-#{last_name.parameterize}",
    status: CANDIDATE_STATUSES[index % CANDIDATE_STATUSES.size],
    notes: CANDIDATE_NOTES[index % CANDIDATE_NOTES.size],
    source: CANDIDATE_SOURCES[index % CANDIDATE_SOURCES.size]
  )

  candidates << candidate
end

puts "#{Candidate.count} candidates ready."

first_candidate = Candidate.order(:id).first
if first_candidate
  candidate_user = User.find_or_create_by!(email: "candidate@rivyr.test") do |u|
    u.password = "password"
    u.first_name = first_candidate.first_name
    u.last_name = first_candidate.last_name
    u.phone = first_candidate.phone
    u.status = "active"
    u.role = "candidate"
  end
  candidate_user.update!(status: "active", role: "candidate")
  first_candidate.update!(user: candidate_user)
end

# --------------------------------------------------
# Placements
# --------------------------------------------------

puts "Seeding placements..."
placements = PLACEMENTS_DATA.map.with_index do |data, index|
  mission = Mission.find_by!(reference: data[:mission_reference])
  candidate = candidates[data[:candidate_index]]
  fee_cents = (data[:annual_salary_cents] * data[:fee_rate]).to_i

  placement = Placement.find_or_create_by!(mission: mission, candidate: candidate) do |p|
    p.hired_at = seeded_date(60 - (index * 7))
    p.annual_salary_cents = data[:annual_salary_cents]
    p.placement_fee_cents = fee_cents
    p.status = data[:status]
    p.notes = "Placement realise sur une fonction a fort enjeu apres un process structure, une shortlist ciblee et une prise de decision rapide du client."
  end

  placement.update!(
    hired_at: seeded_date(60 - (index * 7)),
    annual_salary_cents: data[:annual_salary_cents],
    placement_fee_cents: fee_cents,
    status: data[:status],
    notes: "Placement realise sur une fonction a fort enjeu apres un process structure, une shortlist ciblee et une prise de decision rapide du client."
  )

  placement
end

puts "#{Placement.count} placements ready."

# --------------------------------------------------
# Invoices
# --------------------------------------------------

puts "Seeding invoices..."
invoices = placements.map.with_index do |placement, index|
  number = "FAC-#{Date.current.year}-#{format('%04d', index + 1)}"

  invoice = Invoice.find_or_create_by!(number: number) do |i|
    i.invoice_type = 'client'
    i.issue_date = placement.hired_at + 5
    i.paid_date = index.even? ? placement.hired_at + 20 : nil
    i.amount_cents = placement.placement_fee_cents
    i.placement = placement
    i.status = index.even? ? 'paid' : 'issued'
  end

  invoice.update!(
    invoice_type: 'client',
    issue_date: placement.hired_at + 5,
    paid_date: index.even? ? placement.hired_at + 20 : nil,
    amount_cents: placement.placement_fee_cents,
    placement: placement,
    status: index.even? ? 'paid' : 'issued'
  )

  invoice
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
# Commissions
# --------------------------------------------------

puts "Seeding commissions..."
commissions = placements.map.with_index do |placement, index|
  rule = COMMISSION_RULES[index % COMMISSION_RULES.size]
  ratio = commission_ratio(rule)
  freelancer_share = (placement.placement_fee_cents * ratio).to_i
  rivyr_share = placement.placement_fee_cents - freelancer_share

  commission = Commission.find_or_create_by!(placement: placement) do |c|
    c.commission_rule = rule
    c.status = index.even? ? 'paid' : 'eligible'
    c.gross_amount_cents = placement.placement_fee_cents
    c.rivyr_share_cents = rivyr_share
    c.freelancer_share_cents = freelancer_share
    c.client_payment_required = true
    c.eligible_for_invoicing_at = placement.hired_at + 3
  end

  commission.update!(
    commission_rule: rule,
    status: index.even? ? 'paid' : 'eligible',
    gross_amount_cents: placement.placement_fee_cents,
    rivyr_share_cents: rivyr_share,
    freelancer_share_cents: freelancer_share,
    client_payment_required: true,
    eligible_for_invoicing_at: placement.hired_at + 3
  )

  commission
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
# Payments
# --------------------------------------------------

puts "Seeding payments..."
placements.each_with_index do |placement, index|
  invoice = invoices[index]
  commission = commissions[index]

  client_payment_ref = "PAY-CLI-#{format('%04d', index + 1)}"
  client_payment = Payment.find_or_create_by!(reference: client_payment_ref) do |payment|
    payment.invoice = invoice
    payment.commission = commission
    payment.amount_cents = invoice.amount_cents
    payment.paid_at = invoice.paid_date&.to_time&.change(hour: 10, min: 0)
    payment.payment_type = 'client_payment'
    payment.status = invoice.status == 'paid' ? 'paid' : 'pending'
  end

  client_payment.update!(
    invoice: invoice,
    commission: commission,
    amount_cents: invoice.amount_cents,
    paid_at: invoice.paid_date&.to_time&.change(hour: 10, min: 0),
    payment_type: 'client_payment',
    status: invoice.status == 'paid' ? 'paid' : 'pending'
  )

  freelancer_payment_ref = "PAY-FREE-#{format('%04d', index + 1)}"
  freelancer_payment = Payment.find_or_create_by!(reference: freelancer_payment_ref) do |payment|
    payment.invoice = invoice
    payment.commission = commission
    payment.amount_cents = commission.freelancer_share_cents
    payment.paid_at = (invoice.paid_date || Date.current).to_time.change(hour: 15, min: 0)
    payment.payment_type = 'freelancer_payout'
    payment.status = invoice.status == 'paid' ? 'paid' : 'pending'
  end

  freelancer_payment.update!(
    invoice: invoice,
    commission: commission,
    amount_cents: commission.freelancer_share_cents,
    paid_at: (invoice.paid_date || Date.current).to_time.change(hour: 15, min: 0),
    payment_type: 'freelancer_payout',
    status: invoice.status == 'paid' ? 'paid' : 'pending'
  )
end
puts "#{Payment.count} payments ready."

puts "Seeding payout requests..."
freelancer_invoice_sample = Invoice.where(invoice_type: "freelancer").first
if freelancer_invoice_sample
  PayoutRequest.find_or_create_by!(user: freelancer_invoice_sample.placement.mission.freelancer_profile.user, invoice: freelancer_invoice_sample) do |request|
    request.amount_cents = freelancer_invoice_sample.amount_cents
    request.billing_number = freelancer_invoice_sample.number
    request.status = "pending"
    request.requested_at = Time.current
    request.bank_account_label = "Compte principal"
  end
end
puts "#{PayoutRequest.count} payout requests ready."

# --------------------------------------------------
# Claire Dumont - finance demo dataset
# --------------------------------------------------

puts "Seeding dedicated finance demo for Claire Dumont..."

claire_user = User.find_by!(email: "claire.dumont@rivyr.test")
claire_profile = FreelancerProfile.find_by!(user: claire_user)
fallback_profile = FreelancerProfile.where.not(id: claire_profile.id).first

if fallback_profile
  Mission.where(freelancer_profile_id: claire_profile.id).update_all(freelancer_profile_id: fallback_profile.id)
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
    brief_summary: MISSION_SUMMARIES[index % MISSION_SUMMARIES.size],
    compensation_summary: COMPENSATION_SUMMARIES[index % COMPENSATION_SUMMARIES.size],
    search_constraints: SEARCH_CONSTRAINTS[index % SEARCH_CONSTRAINTS.size],
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
