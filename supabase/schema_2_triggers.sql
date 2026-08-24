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
