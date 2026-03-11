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
  { reference: 'MIS-2026-020', client_legal_name: 'Seine Corporate Finance SAS', specialty: 'Juridique', title: 'Responsable Juridique', priority: 'medium' }
].freeze

PLACEMENTS_DATA = [
  { mission_reference: 'MIS-2026-001', candidate_index: 0, annual_salary_cents: 13_000_000, fee_rate: 0.22, status: 'paid' },
  { mission_reference: 'MIS-2026-003', candidate_index: 1, annual_salary_cents: 14_500_000, fee_rate: 0.23, status: 'validated' },
  { mission_reference: 'MIS-2026-005', candidate_index: 2, annual_salary_cents: 12_000_000, fee_rate: 0.20, status: 'invoiced' },
  { mission_reference: 'MIS-2026-010', candidate_index: 3, annual_salary_cents: 11_000_000, fee_rate: 0.21, status: 'paid' },
  { mission_reference: 'MIS-2026-015', candidate_index: 4, annual_salary_cents: 16_000_000, fee_rate: 0.25, status: 'pending_guarantee' }
].freeze

MISSION_SUMMARIES = [
  "Mission confiee dans un contexte de structuration, avec un besoin fort de niveau, de credibilite et de capacite a embarquer les equipes.",
  "Recherche sensible sur une fonction cle, avec un enjeu important d alignement entre expertise metier, leadership et culture d entreprise.",
  "Recrutement strategique visant a securiser une etape de croissance, dans un environnement ou la posture et la capacite de pilotage sont determinantes.",
  "Mission de recrutement haut de gamme sur un poste impactant, avec une attente forte sur la justesse d evaluation et la qualite de shortlist."
].freeze

COMPENSATION_SUMMARIES = [
  "Package compose d un fixe attractif, d un variable selon le niveau de responsabilite et d avantages associes au poste.",
  "Remuneration a definir selon experience, avec variable, vehicule ou avantages selon la fonction.",
  "Package global competitif, construit pour attirer un profil senior capable de prendre rapidement de la hauteur."
].freeze

SEARCH_CONSTRAINTS = [
  "Le client attend un candidat ayant deja evolue dans un environnement comparable, capable de piloter, structurer et faire adherer.",
  "Une experience sectorielle ou contextuelle proche est fortement attendue, avec un vrai niveau d autonomie et de leadership.",
  "Le poste suppose une forte credibilite metier, de la maturite relationnelle et une capacite a tenir un role expose."
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
  matching_freelancer = FreelancerProfile.joins(:specialty).find_by(specialties: { name: data[:specialty] }) || FreelancerProfile.first

  mission = Mission.find_or_create_by!(reference: data[:reference]) do |m|
    m.region = region
    m.freelancer_profile = matching_freelancer
    m.mission_type = mission_type_for(index)
    m.title = data[:title]
    m.status = mission_status_for(index)
    m.client_contact = contact
    m.location = client.location
    m.contract_signed = true
    m.opened_at = seeded_date(180 - (index * 5))
    m.started_at = seeded_date(170 - (index * 5))
    m.closed_at = mission_status_for(index) == 'closed' ? seeded_date(120 - (index * 3)) : nil
    m.priority_level = data[:priority]
    m.brief_summary = MISSION_SUMMARIES[index % MISSION_SUMMARIES.size]
    m.compensation_summary = COMPENSATION_SUMMARIES[index % COMPENSATION_SUMMARIES.size]
    m.search_constraints = SEARCH_CONSTRAINTS[index % SEARCH_CONSTRAINTS.size]
    m.origin_type = MISSION_ORIGINS[index % MISSION_ORIGINS.size]
    m.specialty = specialty
  end

  mission.update!(
    region: region,
    freelancer_profile: matching_freelancer,
    mission_type: mission_type_for(index),
    title: data[:title],
    status: mission_status_for(index),
    client_contact: contact,
    location: client.location,
    contract_signed: true,
    opened_at: seeded_date(180 - (index * 5)),
    started_at: seeded_date(170 - (index * 5)),
    closed_at: mission_status_for(index) == 'closed' ? seeded_date(120 - (index * 3)) : nil,
    priority_level: data[:priority],
    brief_summary: MISSION_SUMMARIES[index % MISSION_SUMMARIES.size],
    compensation_summary: COMPENSATION_SUMMARIES[index % COMPENSATION_SUMMARIES.size],
    search_constraints: SEARCH_CONSTRAINTS[index % SEARCH_CONSTRAINTS.size],
    origin_type: MISSION_ORIGINS[index % MISSION_ORIGINS.size],
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
puts "============================"
