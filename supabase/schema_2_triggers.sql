-- Triggers — automatismes qui gardent les données cohérentes sans
-- dépendre de ce que l'app pense d'écrire.
-- À exécuter après schema_1_types_tables.sql.

-- ============================================================
-- 1. Création automatique du profil à l'inscription.
-- ============================================================

create or replace function gerer_nouvel_utilisateur()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profils (id, nom_complet, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'nom_complet', new.email), new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function gerer_nouvel_utilisateur();

-- ============================================================
-- 2. Le créateur d'un espace en devient automatiquement propriétaire.
-- ============================================================

create or replace function gerer_nouvel_espace()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.espace_membres (espace_id, user_id, role)
  values (new.id, new.created_by, 'proprietaire');
  return new;
end;
$$;

create trigger on_espace_created
  after insert on espaces
  for each row execute function gerer_nouvel_espace();

-- ============================================================
-- 3. Chaque versement (tranche) recalcule le total payé, le statut et
--    la date du dernier paiement sur la cotisation du membre concerné.
--    L'app ne doit jamais écrire montant_paye/statut/dernier_paiement
--    directement sur paiements_cotisation — uniquement insérer/modifier
--    des lignes dans "tranches".
-- ============================================================

create or replace function recalculer_paiement_cotisation()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_paiement_id uuid := coalesce(new.paiement_cotisation_id, old.paiement_cotisation_id);
  v_total numeric(14,2);
  v_dernier timestamptz;
  v_du numeric(14,2);
  v_statut_actuel statut_paiement_cotisation;
begin
  select coalesce(sum(montant), 0), max(date)
    into v_total, v_dernier
    from tranches
    where paiement_cotisation_id = v_paiement_id;

  select montant_du, statut into v_du, v_statut_actuel
    from paiements_cotisation where id = v_paiement_id;

  update paiements_cotisation
  set
    montant_paye = v_total,
    dernier_paiement = v_dernier,
    -- Une exonération est une décision manuelle : on ne l'écrase pas
    -- juste parce qu'un versement arrive ou disparaît. Cast explicite
    -- nécessaire : un CASE dont toutes les branches sont des littéraux
    -- texte est typé "text" par Postgres, pas assignable tel quel à une
    -- colonne enum.
    statut = (case
      when v_statut_actuel = 'exonere' then 'exonere'
      when v_total >= v_du then 'paye'
      when v_total > 0 then 'partiel'
      else 'impaye'
    end)::statut_paiement_cotisation
  where id = v_paiement_id;

  return coalesce(new, old);
end;
$$;

create trigger on_tranche_changee
  after insert or update or delete on tranches
  for each row execute function recalculer_paiement_cotisation();

-- ============================================================
-- 4. Un versement inter-espace (contribution_versements) met à jour
--    le total reçu et le statut de la contribution.
-- ============================================================

create or replace function recalculer_contribution()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_contribution_id uuid := coalesce(new.contribution_id, old.contribution_id);
  v_total numeric(14,2);
  v_demande numeric(14,2);
begin
  select coalesce(sum(montant), 0) into v_total
    from contribution_versements where contribution_id = v_contribution_id;

  select montant_demande into v_demande from contributions where id = v_contribution_id;

  update contributions
  set
    montant_recu = v_total,
    -- Cast explicite : voir la même remarque sur
    -- recalculer_paiement_cotisation() plus haut dans ce fichier.
    statut = (case
      when v_total >= v_demande then 'paye'
      when v_total > 0 then 'partiel'
      else 'en_attente'
    end)::statut_contribution
  where id = v_contribution_id;

  return coalesce(new, old);
end;
$$;

create trigger on_versement_contribution_change
  after insert or update or delete on contribution_versements
  for each row execute function recalculer_contribution();

-- ============================================================
-- 4bis. Chaque fiche de contributions_evenement recalcule le total
--    collecté et le nombre de participants sur l'événement parent.
--    L'app ne doit jamais écrire montant_collecte/participants
--    directement sur evenements — uniquement insérer/modifier des
--    lignes dans "contributions_evenement".
-- ============================================================

create or replace function recalculer_evenement()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_evenement_id uuid := coalesce(new.evenement_id, old.evenement_id);
  v_total numeric(14,2);
  v_participants int;
begin
  select coalesce(sum(montant), 0), count(*)
    into v_total, v_participants
    from contributions_evenement
    where evenement_id = v_evenement_id;

  update evenements
  set montant_collecte = v_total,
      participants = v_participants
  where id = v_evenement_id;

  return coalesce(new, old);
end;
$$;

create trigger on_contribution_evenement_changee
  after insert or update or delete on contributions_evenement
  for each row execute function recalculer_evenement();

-- ============================================================
-- 5. Notifications automatiques — l'app ne crée jamais de notification
--    elle-même, seule la base sait avec certitude quand un événement
--    notifiable s'est produit. Envoyées aux gérants (propriétaire,
--    administrateur, trésorier) de l'espace concerné.
-- ============================================================

create or replace function notifier_nouvelle_contribution()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into notifications (espace_id, user_id, type, titre, description)
  select new.espace_cible_id, em.user_id, 'contribution_demandee',
         'Nouvelle demande de contribution',
         new.projet || ' — ' || new.montant_demande::text || ' demandés'
  from espace_membres em
  where em.espace_id = new.espace_cible_id
    and em.role in ('proprietaire', 'administrateur', 'tresorier');
  return new;
end;
$$;

create trigger on_contribution_creee
  after insert on contributions
  for each row execute function notifier_nouvelle_contribution();

create or replace function notifier_versement_contribution()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_espace_demandeur uuid;
  v_projet text;
begin
  select espace_demandeur_id, projet into v_espace_demandeur, v_projet
    from contributions where id = new.contribution_id;

  insert into notifications (espace_id, user_id, type, titre, description)
  select v_espace_demandeur, em.user_id, 'contribution_recue',
         'Versement reçu', v_projet || ' — ' || new.montant::text || ' reçus'
  from espace_membres em
  where em.espace_id = v_espace_demandeur
    and em.role in ('proprietaire', 'administrateur', 'tresorier');
  return new;
end;
$$;

create trigger on_versement_cree
  after insert on contribution_versements
  for each row execute function notifier_versement_contribution();

-- ============================================================
-- 6. Journal d'audit — trace automatiquement les écritures de
--    trésorerie et les changements du registre des membres. L'app
--    n'écrit jamais elle-même dans entrees_journal.
-- ============================================================

-- Partagée entre triggers de tables différentes : cotisations et clotures
-- ont un espace_id direct, mais paiements_cotisation/tranches/
-- contribution_versements ne l'ont pas et doivent le résoudre par
-- jointure. Piège plpgsql : on ne peut PAS faire new.champ/old.champ par
-- branche TG_TABLE_NAME ici — Postgres valide TOUTES les branches d'un
-- case contre le type réel de l'enregistrement du déclenchement en cours,
-- même les branches jamais empruntées, et l'appel échoue avec
-- "record "new" has no field ...". D'où l'accès JSONB dynamique
-- (to_jsonb(new)->>'champ'), qui ne référence aucun nom de champ à la
-- compilation.
create or replace function journaliser()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_espace_id uuid;
  v_new jsonb;
  v_old jsonb;
  v_utilisateur text;
  v_role text;
  v_libelle_table text;
  v_masculin boolean;
  v_suffixe text;
  v_action text;
begin
  if TG_OP in ('INSERT', 'UPDATE') then
    v_new := to_jsonb(new);
  end if;
  if TG_OP in ('UPDATE', 'DELETE') then
    v_old := to_jsonb(old);
  end if;

  v_espace_id := case TG_TABLE_NAME
    when 'paiements_cotisation' then
      (select c.espace_id from cotisations c
       where c.id = coalesce(v_new->>'cotisation_id', v_old->>'cotisation_id')::uuid)
    when 'tranches' then
      (select c.espace_id from paiements_cotisation pc
         join cotisations c on c.id = pc.cotisation_id
       where pc.id = coalesce(v_new->>'paiement_cotisation_id', v_old->>'paiement_cotisation_id')::uuid)
    when 'contributions' then
      coalesce(v_new->>'espace_demandeur_id', v_old->>'espace_demandeur_id')::uuid
    when 'contribution_versements' then
      (select co.espace_demandeur_id from contributions co
       where co.id = coalesce(v_new->>'contribution_id', v_old->>'contribution_id')::uuid)
    else
      coalesce(v_new->>'espace_id', v_old->>'espace_id')::uuid
  end;

  -- Une suppression d'espace entraîne la suppression en cascade de ses
  -- recettes/dépenses/membres/cotisations/..., ce qui déclenche ce trigger
  -- alors que l'espace référencé disparaît dans la même transaction :
  -- inutile (et impossible, contrainte de clé étrangère) de journaliser
  -- dans ce cas. v_espace_id peut aussi être null si la ligne parente a
  -- déjà été supprimée dans la même transaction (cascade).
  if v_espace_id is null or not exists (select 1 from espaces where id = v_espace_id) then
    return coalesce(new, old);
  end if;

  select nom_complet into v_utilisateur from profils where id = auth.uid();
  v_role := coalesce((role_dans_espace(v_espace_id))::text, '');

  v_libelle_table := case TG_TABLE_NAME
    when 'recettes' then 'Recette'
    when 'depenses' then 'Dépense'
    when 'membres' then 'Membre'
    when 'cotisations' then 'Cotisation'
    when 'paiements_cotisation' then 'Paiement de cotisation'
    when 'tranches' then 'Versement de cotisation'
    when 'contributions' then 'Contribution inter-espaces'
    when 'contribution_versements' then 'Versement de contribution'
    when 'clotures' then 'Clôture de caisse'
    else TG_TABLE_NAME
  end;
  v_masculin := TG_TABLE_NAME in
    ('membres', 'paiements_cotisation', 'tranches', 'contribution_versements');
  v_suffixe := case TG_OP
    when 'INSERT' then (case when v_masculin then 'créé' else 'créée' end)
    when 'UPDATE' then (case when v_masculin then 'modifié' else 'modifiée' end)
    when 'DELETE' then (case when v_masculin then 'supprimé' else 'supprimée' end)
  end;
  v_action := v_libelle_table || ' ' || v_suffixe;

  insert into entrees_journal (espace_id, utilisateur, role, action, ancienne_valeur, nouvelle_valeur)
  values (
    v_espace_id,
    coalesce(v_utilisateur, 'Compte supprimé'),
    v_role,
    v_action,
    case when TG_OP in ('UPDATE', 'DELETE') then row_to_json(old)::text else null end,
    case when TG_OP in ('INSERT', 'UPDATE') then row_to_json(new)::text else null end
  );
  return coalesce(new, old);
end;
$$;

create trigger journal_recettes after insert or update or delete on recettes
  for each row execute function journaliser();
create trigger journal_depenses after insert or update or delete on depenses
  for each row execute function journaliser();
create trigger journal_membres after insert or update or delete on membres
  for each row execute function journaliser();
create trigger journal_cotisations after insert or update or delete on cotisations
  for each row execute function journaliser();
create trigger journal_paiements_cotisation after insert or update or delete on paiements_cotisation
  for each row execute function journaliser();
create trigger journal_tranches after insert or update or delete on tranches
  for each row execute function journaliser();
create trigger journal_contributions after insert or update or delete on contributions
  for each row execute function journaliser();
create trigger journal_contribution_versements after insert or update or delete on contribution_versements
  for each row execute function journaliser();
create trigger journal_clotures after insert or update or delete on clotures
  for each row execute function journaliser();

-- ============================================================
-- 7. Notifications programmées — temps réel pour les paiements, et
--    quotidien (pg_cron) pour les retards de cotisation et les
--    événements qui approchent.
-- ============================================================

create or replace function notifier_nouveau_paiement()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_espace_id uuid;
  v_nom_membre text;
  v_nom_cotisation text;
begin
  select c.espace_id, c.nom into v_espace_id, v_nom_cotisation
    from paiements_cotisation pc join cotisations c on c.id = pc.cotisation_id
    where pc.id = new.paiement_cotisation_id;

  select m.prenom || ' ' || m.nom into v_nom_membre
    from paiements_cotisation pc join membres m on m.id = pc.membre_id
    where pc.id = new.paiement_cotisation_id;

  insert into notifications (espace_id, user_id, type, titre, description)
  select v_espace_id, em.user_id, 'nouveau_paiement',
         'Nouveau paiement',
         coalesce(v_nom_membre, 'Un membre') || ' — ' || coalesce(v_nom_cotisation, '') || ' : ' || new.montant::text
  from espace_membres em
  where em.espace_id = v_espace_id
    and em.role in ('proprietaire', 'administrateur', 'tresorier');
  return new;
end;
$$;

create trigger on_tranche_creee_notif
  after insert on tranches
  for each row execute function notifier_nouveau_paiement();

create or replace function notifier_cotisations_en_retard()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  update paiements_cotisation pc
  set statut = 'en_retard'
  from cotisations c
  where c.id = pc.cotisation_id
    and c.date_limite < current_date
    and pc.statut in ('impaye', 'partiel');

  insert into notifications (espace_id, user_id, type, titre, description)
  select c.espace_id, em.user_id, 'cotisation_retard',
         'Cotisations en retard',
         count(*)::text || ' paiement(s) en retard'
  from paiements_cotisation pc
  join cotisations c on c.id = pc.cotisation_id
  join espace_membres em on em.espace_id = c.espace_id
    and em.role in ('proprietaire', 'administrateur', 'tresorier')
  where pc.statut = 'en_retard'
    and not exists (
      select 1 from notifications n
      where n.espace_id = c.espace_id and n.user_id = em.user_id
        and n.type = 'cotisation_retard' and n.date::date = current_date
    )
  group by c.espace_id, em.user_id;
end;
$$;

create or replace function notifier_evenements_bientot()
returns void
language plpgsql
security definer set search_path = public
as $$
begin
  insert into notifications (espace_id, user_id, type, titre, description)
  select e.espace_id, em.user_id, 'evenement_bientot',
         'Événement bientôt', e.nom || ' commence le ' || to_char(e.date_debut, 'DD/MM/YYYY')
  from evenements e
  join espace_membres em on em.espace_id = e.espace_id
    and em.role in ('proprietaire', 'administrateur', 'tresorier')
  where e.statut in ('planifie', 'actif')
    and e.date_debut between current_date and current_date + interval '3 days'
    and not exists (
      select 1 from notifications n
      where n.espace_id = e.espace_id and n.user_id = em.user_id
        and n.type = 'evenement_bientot' and n.date::date = current_date
    );
end;
$$;

create extension if not exists pg_cron with schema extensions;

select cron.schedule(
  'notifications-quotidiennes',
  '0 6 * * *',
  $$ select notifier_cotisations_en_retard(); select notifier_evenements_bientot(); $$
);

-- ============================================================
-- 8. Retrait des grants EXECUTE implicites — Postgres accorde EXECUTE à
--    PUBLIC (donc anon + authenticated) par défaut à la création d'une
--    fonction. notifier_cotisations_en_retard()/notifier_evenements_bientot()
--    sont RETURNS void (pas trigger) et SECURITY DEFINER : sans ce retrait,
--    n'importe qui, même non connecté, pouvait les appeler directement via
--    /rest/v1/rpc/... — elles écrivent dans TOUS les espaces de la base,
--    sans aucune vérification d'appartenance. Seul le job pg_cron
--    ci-dessus doit les déclencher (il s'exécute avec les droits du
--    propriétaire de la fonction, indépendant de ces grants).
--    Les fonctions RETURNS trigger ci-dessous ne sont de toute façon
--    jamais appelables directement (Postgres le refuse hors contexte
--    trigger) : le retrait est une question d'hygiène de la surface d'API
--    publique, pas une faille exploitable.
-- ============================================================

revoke execute on function notifier_cotisations_en_retard() from anon, authenticated;
revoke execute on function notifier_evenements_bientot() from anon, authenticated;

revoke execute on function gerer_nouvel_utilisateur() from anon, authenticated;
revoke execute on function gerer_nouvel_espace() from anon, authenticated;
revoke execute on function journaliser() from anon, authenticated;
revoke execute on function recalculer_paiement_cotisation() from anon, authenticated;
revoke execute on function recalculer_contribution() from anon, authenticated;
revoke execute on function recalculer_evenement() from anon, authenticated;
revoke execute on function notifier_nouvelle_contribution() from anon, authenticated;
revoke execute on function notifier_versement_contribution() from anon, authenticated;
revoke execute on function notifier_nouveau_paiement() from anon, authenticated;
