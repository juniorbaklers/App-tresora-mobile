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
    -- juste parce qu'un versement arrive ou disparaît.
    statut = case
      when v_statut_actuel = 'exonere' then 'exonere'
      when v_total >= v_du then 'paye'
      when v_total > 0 then 'partiel'
      else 'impaye'
    end
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
    statut = case
      when v_total >= v_demande then 'paye'
      when v_total > 0 then 'partiel'
      else 'en_attente'
    end
  where id = v_contribution_id;

  return coalesce(new, old);
end;
$$;

create trigger on_versement_contribution_change
  after insert or update or delete on contribution_versements
  for each row execute function recalculer_contribution();

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

create or replace function journaliser()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  v_espace_id uuid := coalesce(new.espace_id, old.espace_id);
  v_utilisateur text;
  v_role text;
  v_libelle_table text;
  v_action text;
begin
  select nom_complet into v_utilisateur from profils where id = auth.uid();
  v_role := coalesce((role_dans_espace(v_espace_id))::text, '');
  v_libelle_table := case TG_TABLE_NAME
    when 'recettes' then 'Recette'
    when 'depenses' then 'Dépense'
    when 'membres' then 'Membre'
    else TG_TABLE_NAME
  end;
  v_action := v_libelle_table || ' ' || case TG_OP
    when 'INSERT' then 'créée'
    when 'UPDATE' then 'modifiée'
    when 'DELETE' then 'supprimée'
  end;

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
