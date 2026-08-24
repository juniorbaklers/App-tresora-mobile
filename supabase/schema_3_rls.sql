-- Row Level Security — tout l'accès aux données passe par l'appartenance
-- à un espace (espace_membres) et le rôle qui y est associé.
-- À exécuter après schema_1_types_tables.sql et schema_2_triggers.sql.

-- ============================================================
-- Fonctions helper — security definer pour éviter toute récursion RLS
-- (une policy sur espace_membres qui interrogerait espace_membres via
-- une fonction non security-definer boucle indéfiniment).
-- ============================================================

create or replace function role_dans_espace(p_espace_id uuid)
returns role_espace
language sql stable security definer set search_path = public
as $$
  select role from espace_membres where espace_id = p_espace_id and user_id = auth.uid();
$$;

create or replace function est_membre_espace(p_espace_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists(select 1 from espace_membres where espace_id = p_espace_id and user_id = auth.uid());
$$;

-- Propriétaire/administrateur/trésorier : peut manipuler l'argent.
create or replace function peut_gerer(p_espace_id uuid)
returns boolean language sql stable
as $$ select role_dans_espace(p_espace_id) in ('proprietaire', 'administrateur', 'tresorier'); $$;

-- Propriétaire/administrateur : peut changer les réglages de l'espace.
create or replace function peut_administrer(p_espace_id uuid)
returns boolean language sql stable
as $$ select role_dans_espace(p_espace_id) in ('proprietaire', 'administrateur'); $$;

-- Ajoute les "responsables" (ex: chef de groupe/section) à la gestion des
-- membres et cotisations, sans leur donner accès aux recettes/dépenses.
create or replace function peut_gerer_membres(p_espace_id uuid)
returns boolean language sql stable
as $$ select role_dans_espace(p_espace_id) in ('proprietaire', 'administrateur', 'tresorier', 'responsable'); $$;

-- ============================================================
-- Activation RLS sur toutes les tables
-- ============================================================

alter table profils enable row level security;
alter table espaces enable row level security;
alter table espace_membres enable row level security;
alter table invitations enable row level security;
alter table membres enable row level security;
alter table cotisations enable row level security;
alter table paiements_cotisation enable row level security;
alter table tranches enable row level security;
alter table rappels enable row level security;
alter table corrections enable row level security;
alter table recettes enable row level security;
alter table depenses enable row level security;
alter table evenements enable row level security;
alter table contributions enable row level security;
alter table contribution_versements enable row level security;
alter table notifications enable row level security;
alter table entrees_journal enable row level security;
alter table clotures enable row level security;

-- ============================================================
-- PROFILS
-- ============================================================

create policy "profils_lecture" on profils for select using (auth.role() = 'authenticated');
create policy "profils_maj_soi_meme" on profils for update using (id = auth.uid());
-- Pas de policy insert : la création passe uniquement par le trigger
-- (security definer) sur auth.users, jamais par un insert direct de l'app.

-- ============================================================
-- ESPACES
-- ============================================================

create policy "espaces_lecture" on espaces for select using (est_membre_espace(id));
create policy "espaces_creation" on espaces for insert with check (created_by = auth.uid());
create policy "espaces_maj" on espaces for update using (peut_administrer(id));
create policy "espaces_suppr" on espaces for delete using (role_dans_espace(id) = 'proprietaire');

-- ============================================================
-- ESPACE_MEMBRES
-- ============================================================

create policy "espace_membres_lecture" on espace_membres for select using (est_membre_espace(espace_id));
create policy "espace_membres_ajout" on espace_membres for insert with check (peut_administrer(espace_id));
create policy "espace_membres_maj" on espace_membres for update using (peut_administrer(espace_id));
create policy "espace_membres_suppr" on espace_membres for delete using (peut_administrer(espace_id));

-- ============================================================
-- INVITATIONS
-- ============================================================

create policy "invitations_lecture" on invitations for select using (peut_administrer(espace_id));
create policy "invitations_creation" on invitations for insert
  with check (peut_administrer(espace_id) and invite_par = auth.uid());
create policy "invitations_maj" on invitations for update using (peut_administrer(espace_id));
create policy "invitations_suppr" on invitations for delete using (peut_administrer(espace_id));

-- ============================================================
-- MEMBRES
-- ============================================================

create policy "membres_lecture" on membres for select using (est_membre_espace(espace_id));
create policy "membres_ecriture" on membres for insert with check (peut_gerer_membres(espace_id));
create policy "membres_maj" on membres for update using (peut_gerer_membres(espace_id));
create policy "membres_suppr" on membres for delete using (peut_administrer(espace_id));

-- ============================================================
-- COTISATIONS
-- ============================================================

create policy "cotisations_lecture" on cotisations for select using (est_membre_espace(espace_id));
create policy "cotisations_ecriture" on cotisations for insert with check (peut_gerer_membres(espace_id));
create policy "cotisations_maj" on cotisations for update using (peut_gerer_membres(espace_id));
create policy "cotisations_suppr" on cotisations for delete using (peut_gerer(espace_id));

-- ============================================================
-- PAIEMENTS_COTISATION (scoping via cotisations.espace_id)
-- ============================================================

create policy "paiements_lecture" on paiements_cotisation for select using (
  exists (select 1 from cotisations c where c.id = cotisation_id and est_membre_espace(c.espace_id))
);
create policy "paiements_ecriture" on paiements_cotisation for insert with check (
  exists (select 1 from cotisations c where c.id = cotisation_id and peut_gerer_membres(c.espace_id))
);
create policy "paiements_maj" on paiements_cotisation for update using (
  exists (select 1 from cotisations c where c.id = cotisation_id and peut_gerer_membres(c.espace_id))
);
create policy "paiements_suppr" on paiements_cotisation for delete using (
  exists (select 1 from cotisations c where c.id = cotisation_id and peut_gerer(c.espace_id))
);

-- ============================================================
-- TRANCHES (scoping via paiements_cotisation -> cotisations.espace_id)
-- ============================================================

create policy "tranches_lecture" on tranches for select using (
  exists (
    select 1 from paiements_cotisation pc
    join cotisations c on c.id = pc.cotisation_id
    where pc.id = paiement_cotisation_id and est_membre_espace(c.espace_id)
  )
);
create policy "tranches_ecriture" on tranches for insert with check (
  exists (
    select 1 from paiements_cotisation pc
    join cotisations c on c.id = pc.cotisation_id
    where pc.id = paiement_cotisation_id and peut_gerer_membres(c.espace_id)
  )
);
create policy "tranches_maj" on tranches for update using (
  exists (
    select 1 from paiements_cotisation pc
    join cotisations c on c.id = pc.cotisation_id
    where pc.id = paiement_cotisation_id and peut_gerer_membres(c.espace_id)
  )
);
create policy "tranches_suppr" on tranches for delete using (
  exists (
    select 1 from paiements_cotisation pc
    join cotisations c on c.id = pc.cotisation_id
    where pc.id = paiement_cotisation_id and peut_gerer_membres(c.espace_id)
  )
);

-- ============================================================
-- RAPPELS (scoping via cotisations.espace_id)
-- ============================================================

create policy "rappels_lecture" on rappels for select using (
  exists (select 1 from cotisations c where c.id = cotisation_id and est_membre_espace(c.espace_id))
);
create policy "rappels_ecriture" on rappels for insert with check (
  exists (select 1 from cotisations c where c.id = cotisation_id and peut_gerer_membres(c.espace_id))
);
create policy "rappels_suppr" on rappels for delete using (
  exists (select 1 from cotisations c where c.id = cotisation_id and peut_gerer_membres(c.espace_id))
);

-- ============================================================
-- CORRECTIONS — jamais modifiables ni supprimables une fois créées
-- (c'est la trace anti-fraude), seulement lues et insérées.
-- ============================================================

create policy "corrections_lecture" on corrections for select using (est_membre_espace(espace_id));
create policy "corrections_creation" on corrections for insert with check (peut_gerer(espace_id));

-- ============================================================
-- RECETTES / DEPENSES — seuls les rôles financiers (pas "responsable")
-- peuvent toucher à l'argent.
-- ============================================================

create policy "recettes_lecture" on recettes for select using (est_membre_espace(espace_id));
create policy "recettes_ecriture" on recettes for insert with check (peut_gerer(espace_id));
create policy "recettes_maj" on recettes for update using (peut_gerer(espace_id));
create policy "recettes_suppr" on recettes for delete using (peut_administrer(espace_id));

create policy "depenses_lecture" on depenses for select using (est_membre_espace(espace_id));
create policy "depenses_ecriture" on depenses for insert with check (peut_gerer(espace_id));
create policy "depenses_maj" on depenses for update using (peut_gerer(espace_id));
create policy "depenses_suppr" on depenses for delete using (peut_administrer(espace_id));

-- ============================================================
-- EVENEMENTS
-- ============================================================

create policy "evenements_lecture" on evenements for select using (est_membre_espace(espace_id));
create policy "evenements_ecriture" on evenements for insert with check (peut_gerer_membres(espace_id));
create policy "evenements_maj" on evenements for update using (peut_gerer_membres(espace_id));
create policy "evenements_suppr" on evenements for delete using (peut_gerer(espace_id));

-- ============================================================
-- CONTRIBUTIONS INTER-ESPACES — visibles des deux côtés, modifiables
-- seulement par le demandeur (le côté qui reçoit gère via les versements).
-- ============================================================

create policy "contributions_lecture" on contributions for select using (
  est_membre_espace(espace_demandeur_id) or est_membre_espace(espace_cible_id)
);
create policy "contributions_creation" on contributions for insert with check (
  peut_gerer(espace_demandeur_id)
);
create policy "contributions_maj" on contributions for update using (
  peut_gerer(espace_demandeur_id)
);
create policy "contributions_suppr" on contributions for delete using (
  peut_gerer(espace_demandeur_id)
);

create policy "versements_lecture" on contribution_versements for select using (
  exists (
    select 1 from contributions co where co.id = contribution_id
    and (est_membre_espace(co.espace_demandeur_id) or est_membre_espace(co.espace_cible_id))
  )
);
-- Seul l'espace sollicité (cible) peut enregistrer qu'il a versé.
create policy "versements_creation" on contribution_versements for insert with check (
  exists (select 1 from contributions co where co.id = contribution_id and peut_gerer(co.espace_cible_id))
);

-- ============================================================
-- NOTIFICATIONS — boîte personnelle.
-- ============================================================

create policy "notifications_lecture" on notifications for select using (user_id = auth.uid());
create policy "notifications_creation" on notifications for insert with check (peut_administrer(espace_id));
create policy "notifications_maj" on notifications for update using (user_id = auth.uid());
create policy "notifications_suppr" on notifications for delete using (user_id = auth.uid());

-- ============================================================
-- JOURNAL D'AUDIT — écriture seule, jamais de update/delete (aucune
-- policy pour ces actions = refusées par défaut sous RLS).
-- ============================================================

create policy "journal_lecture" on entrees_journal for select using (est_membre_espace(espace_id));
create policy "journal_ecriture" on entrees_journal for insert with check (peut_gerer_membres(espace_id));

-- ============================================================
-- CLOTURES
-- ============================================================

create policy "clotures_lecture" on clotures for select using (est_membre_espace(espace_id));
create policy "clotures_ecriture" on clotures for insert with check (peut_gerer(espace_id));
create policy "clotures_maj" on clotures for update using (peut_gerer(espace_id));
create policy "clotures_suppr" on clotures for delete using (peut_administrer(espace_id));
