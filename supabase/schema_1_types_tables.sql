-- Schéma Trésora v2 — fidèle au modèle de données de tresora-app
-- (src/lib/types.ts). À exécuter dans un projet Supabase NEUF et VIDE,
-- indépendant de celui de gestion-caisse-eglise.
--
-- Ordre d'exécution : schema_1_types_tables.sql, puis schema_2_triggers.sql,
-- puis schema_3_rls.sql. Voir supabase/README.md.

-- ============================================================
-- 1. TYPES ÉNUMÉRÉS
-- ============================================================

create type espace_type as enum ('eglise', 'groupe', 'association', 'autre');
create type role_espace as enum ('proprietaire', 'administrateur', 'tresorier', 'responsable', 'membre');
create type devise_code as enum ('XOF', 'XAF', 'GHS', 'EUR', 'USD');
create type statut_membre as enum ('actif', 'inactif');
create type mode_paiement as enum ('especes', 'mobile_money', 'virement', 'cheque');
create type operateur_mobile_money as enum ('orange_money', 'mtn_money', 'moov_money', 'wave');
create type statut_paiement_cotisation as enum ('paye', 'partiel', 'impaye', 'en_retard', 'exonere');
create type periodicite as enum ('unique', 'hebdomadaire', 'mensuelle', 'trimestrielle', 'annuelle', 'personnalisee');
create type statut_cotisation as enum ('active', 'cloturee');
create type categorie_recette as enum (
  'dime', 'offrande_ordinaire', 'offrande_speciale', 'offrande_culte_soir',
  'cotisation', 'don', 'activite', 'autre'
);
create type statut_evenement as enum ('planifie', 'actif', 'termine');
create type statut_contribution as enum ('en_attente', 'partiel', 'paye');
create type type_notification as enum (
  'cotisation_retard', 'nouveau_paiement', 'contribution_demandee',
  'contribution_recue', 'evenement_bientot', 'rapport_disponible'
);

-- ============================================================
-- 2. PROFILS — un par utilisateur (identité globale, indépendante
--    des espaces). Créé automatiquement à l'inscription (trigger).
-- ============================================================

create table profils (
  id uuid primary key references auth.users(id) on delete cascade,
  nom_complet text not null,
  email text not null,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 3. ESPACES — le concept central : chaque organisation (église,
--    groupe, association, ou perso) est une trésorerie indépendante.
-- ============================================================

create table espaces (
  id uuid primary key default gen_random_uuid(),
  nom text not null,
  type espace_type not null default 'eglise',
  initiales text not null,
  couleur text not null default 'bg-primary',
  devise devise_code not null default 'XOF',
  modules text[] not null default array['membres','cotisations','evenements','recettes','depenses','rapports','dons','contributions'],
  solde_initial numeric(14,2) not null default 0,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

-- Rôle de chaque utilisateur dans chaque espace — table de jonction qui
-- porte tout le contrôle d'accès (RLS s'appuie dessus).
create table espace_membres (
  espace_id uuid not null references espaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role role_espace not null default 'membre',
  created_at timestamptz not null default now(),
  primary key (espace_id, user_id)
);

create table invitations (
  id uuid primary key default gen_random_uuid(),
  espace_id uuid not null references espaces(id) on delete cascade,
  email text not null,
  role role_espace not null default 'membre',
  invite_par uuid not null references auth.users(id),
  date timestamptz not null default now(),
  acceptee boolean not null default false
);

-- ============================================================
-- 4. MEMBRES — registre nominatif des cotisants d'un espace
--    (distinct de espace_membres : ce ne sont pas forcément des
--    utilisateurs de l'app, juste des personnes suivies).
-- ============================================================

create table membres (
  id uuid primary key default gen_random_uuid(),
  espace_id uuid not null references espaces(id) on delete cascade,
  nom text not null,
  prenom text not null,
  telephone text not null default '',
  email text,
  fonction text,
  statut statut_membre not null default 'actif',
  date_inscription date not null default current_date,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 5. COTISATIONS — payables en une ou plusieurs tranches.
-- ============================================================

create table cotisations (
  id uuid primary key default gen_random_uuid(),
  espace_id uuid not null references espaces(id) on delete cascade,
  nom text not null,
  description text not null default '',
  montant numeric(14,2) not null check (montant > 0),
  periodicite periodicite not null default 'unique',
  date_debut date not null default current_date,
  date_limite date not null,
  responsable text not null default '',
  statut statut_cotisation not null default 'active',
  created_at timestamptz not null default now()
);

create table paiements_cotisation (
  id uuid primary key default gen_random_uuid(),
  cotisation_id uuid not null references cotisations(id) on delete cascade,
  membre_id uuid not null references membres(id) on delete cascade,
  montant_du numeric(14,2) not null,
  -- Tenu à jour automatiquement par un trigger à chaque insert/delete
  -- sur "tranches" — ne jamais l'écrire directement depuis l'app.
  montant_paye numeric(14,2) not null default 0,
  statut statut_paiement_cotisation not null default 'impaye',
  dernier_paiement timestamptz,
  unique (cotisation_id, membre_id)
);

-- Un versement isolé — une cotisation peut être réglée en plusieurs fois.
create table tranches (
  id uuid primary key default gen_random_uuid(),
  paiement_cotisation_id uuid not null references paiements_cotisation(id) on delete cascade,
  date timestamptz not null default now(),
  montant numeric(14,2) not null check (montant > 0),
  responsable text not null default '',
  mode_paiement mode_paiement,
  operateur operateur_mobile_money,
  reference text
);

-- Rappel envoyé (ou programmé) à un membre pour une cotisation impayée.
create table rappels (
  id uuid primary key default gen_random_uuid(),
  cotisation_id uuid not null references cotisations(id) on delete cascade,
  membre_id uuid not null references membres(id) on delete cascade,
  date timestamptz not null default now(),
  automatique boolean not null default false
);

-- ============================================================
-- 6. TRÉSORERIE — recettes, dépenses, corrections tracées.
-- ============================================================

-- Une correction apportée après coup à un montant ou un texte déjà
-- enregistré. Toujours conservée intégralement (jamais écrasée) : c'est
-- la trace qui protège contre une saisie malhonnête déguisée en « faute
-- de frappe ». table_cible/ligne_id pointent vers la ligne corrigée
-- (recettes ou depenses) sans contrainte FK stricte (générique).
create table corrections (
  id uuid primary key default gen_random_uuid(),
  -- Dénormalisé volontairement : permet à la RLS de vérifier l'appartenance
  -- à l'espace sans jointure vers recettes/depenses (dont l'une des deux
  -- lignes n'existe pas selon table_cible).
  espace_id uuid not null references espaces(id) on delete cascade,
  table_cible text not null check (table_cible in ('recettes', 'depenses')),
  ligne_id uuid not null,
  date date not null default current_date,
  heure time not null default current_time,
  responsable text not null default '',
  raison text not null,
  champ text not null,
  ancienne_valeur text not null,
  nouvelle_valeur text not null,
  created_at timestamptz not null default now()
);

create table recettes (
  id uuid primary key default gen_random_uuid(),
  espace_id uuid not null references espaces(id) on delete cascade,
  date date not null default current_date,
  montant numeric(14,2) not null check (montant > 0),
  categorie categorie_recette not null default 'autre',
  libelle text not null default '',
  responsable text not null default '',
  commentaire text,
  created_at timestamptz not null default now()
);

create table depenses (
  id uuid primary key default gen_random_uuid(),
  espace_id uuid not null references espaces(id) on delete cascade,
  date date not null default current_date,
  montant numeric(14,2) not null check (montant > 0),
  categorie text not null default 'autre',
  description text not null default '',
  beneficiaire text not null default '',
  mode_paiement mode_paiement not null default 'especes',
  responsable text not null default '',
  justificatif boolean not null default false,
  evenement_id uuid,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 7. ÉVÉNEMENTS
-- ============================================================

create table evenements (
  id uuid primary key default gen_random_uuid(),
  espace_id uuid not null references espaces(id) on delete cascade,
  nom text not null,
  description text not null default '',
  date_debut date not null,
  date_fin date not null,
  montant_cible numeric(14,2),
  montant_suggere numeric(14,2),
  montant_collecte numeric(14,2) not null default 0,
  participants int not null default 0,
  statut statut_evenement not null default 'planifie',
  created_at timestamptz not null default now()
);

alter table depenses
  add constraint depenses_evenement_fk foreign key (evenement_id) references evenements(id) on delete set null;

-- Une fiche par contribution individuelle à une collecte : qui a donné,
-- combien, comment, et qui a fait la saisie. montant_collecte/participants
-- sur "evenements" sont recalculés automatiquement par un trigger à chaque
-- fiche insérée/modifiée/supprimée ici — ne jamais les écrire directement.
create table contributions_evenement (
  id uuid primary key default gen_random_uuid(),
  evenement_id uuid not null references evenements(id) on delete cascade,
  nom_contributeur text not null,
  montant numeric(14,2) not null check (montant > 0),
  mode_paiement mode_paiement,
  responsable text not null default '',
  date timestamptz not null default now()
);

-- ============================================================
-- 8. CONTRIBUTIONS INTER-ESPACES — seul canal financier entre deux
--    espaces : l'un demande une somme à l'autre, voit ce qui est versé,
--    mais ne voit jamais comment l'autre a réuni l'argent.
-- ============================================================

create table contributions (
  id uuid primary key default gen_random_uuid(),
  projet text not null,
  description text not null default '',
  espace_demandeur_id uuid not null references espaces(id) on delete cascade,
  espace_cible_id uuid not null references espaces(id) on delete cascade,
  montant_demande numeric(14,2) not null check (montant_demande > 0),
  montant_recu numeric(14,2) not null default 0,
  date_limite date not null,
  statut statut_contribution not null default 'en_attente',
  created_at timestamptz not null default now(),
  check (espace_demandeur_id != espace_cible_id)
);

create table contribution_versements (
  id uuid primary key default gen_random_uuid(),
  contribution_id uuid not null references contributions(id) on delete cascade,
  date timestamptz not null default now(),
  montant numeric(14,2) not null check (montant > 0)
);

-- ============================================================
-- 9. NOTIFICATIONS
-- ============================================================

create table notifications (
  id uuid primary key default gen_random_uuid(),
  espace_id uuid not null references espaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  type type_notification not null,
  titre text not null,
  description text not null default '',
  date timestamptz not null default now(),
  lue boolean not null default false
);

-- ============================================================
-- 10. JOURNAL D'AUDIT — trace toute action significative.
-- ============================================================

create table entrees_journal (
  id uuid primary key default gen_random_uuid(),
  espace_id uuid not null references espaces(id) on delete cascade,
  date date not null default current_date,
  heure time not null default current_time,
  utilisateur text not null default '',
  role text not null default '',
  action text not null,
  ancienne_valeur text,
  nouvelle_valeur text,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 11. CLÔTURE DU DIMANCHE (spécifique église, mais table générique)
-- ============================================================

create table clotures (
  id uuid primary key default gen_random_uuid(),
  espace_id uuid not null references espaces(id) on delete cascade,
  date date not null,
  culte text not null default '',
  offrande_ordinaire numeric(14,2) not null default 0,
  offrande_speciale numeric(14,2) not null default 0,
  dimes numeric(14,2) not null default 0,
  autres_recettes numeric(14,2) not null default 0,
  total_compte numeric(14,2) not null default 0,
  responsable text not null default '',
  justification text,
  created_at timestamptz not null default now(),
  unique (espace_id, date, culte)
);

-- ============================================================
-- Index utiles
-- ============================================================

create index idx_espace_membres_user on espace_membres(user_id);
create index idx_membres_espace on membres(espace_id);
create index idx_cotisations_espace on cotisations(espace_id);
create index idx_paiements_cotisation on paiements_cotisation(cotisation_id);
create index idx_paiements_membre on paiements_cotisation(membre_id);
create index idx_tranches_paiement on tranches(paiement_cotisation_id);
create index idx_recettes_espace_date on recettes(espace_id, date);
create index idx_depenses_espace_date on depenses(espace_id, date);
create index idx_evenements_espace on evenements(espace_id);
create index idx_contributions_evenement on contributions_evenement(evenement_id);
create index idx_contributions_demandeur on contributions(espace_demandeur_id);
create index idx_contributions_cible on contributions(espace_cible_id);
create index idx_notifications_user on notifications(user_id, lue);
create index idx_journal_espace_date on entrees_journal(espace_id, date);
