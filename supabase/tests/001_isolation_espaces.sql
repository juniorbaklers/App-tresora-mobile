-- Comportement attendu : un membre d'un espace ne voit QUE les espaces
-- dont il est membre — jamais un espace étranger, même s'il existe dans
-- la même base. Couvre la policy "espaces_lecture" (schema_3_rls.sql).
--
-- Ne dépend d'aucune donnée réelle : crée son propre espace "étranger"
-- (transaction annulée à la fin, rien ne persiste). Réutilise le premier
-- compte auth existant comme "utilisateur courant" — un seul suffit
-- puisqu'on teste l'appartenance à espace_membres, pas l'identité.
--
-- À exécuter via le SQL Editor Supabase (ou mcp__Supabase__execute_sql) :
-- échoue bruyamment (RAISE EXCEPTION) si l'isolation est cassée, ne laisse
-- aucune trace sinon (ROLLBACK systématique).
--
-- SET LOCAL ROLE + les réglages de session (set_config) doivent rester des
-- instructions top-level, PAS à l'intérieur d'un bloc DO $$ : un
-- changement de rôle fait à l'intérieur d'un bloc PL/pgSQL ne s'applique
-- pas de façon fiable aux statements suivants du même bloc (vérifié
-- empiriquement sur ce projet). D'où la découpe en plusieurs blocs
-- séparés par des variables de session (app.test_*) pour faire passer les
-- valeurs de l'un à l'autre.

begin;

do $$
declare
  v_user_id uuid;
  v_espace_etranger_id uuid := gen_random_uuid();
begin
  select id into v_user_id from auth.users order by created_at limit 1;
  if v_user_id is null then
    raise exception 'Aucun compte auth.users dans cette base — impossible de tester';
  end if;

  -- Espace étranger. Le trigger "le créateur devient propriétaire"
  -- (schema_2_triggers.sql) ajoute automatiquement v_user_id dans
  -- espace_membres pour CET espace — on l'enlève aussitôt (encore avec le
  -- rôle privilégié, donc RLS non concernée) pour simuler le vrai cas :
  -- un espace qui existe, dont cet utilisateur n'est pas membre.
  insert into espaces (id, nom, type, initiales, devise, created_by)
  values (v_espace_etranger_id, 'Espace étranger (test isolation)', 'autre',
          'ET', 'XOF', v_user_id);
  delete from espace_membres
    where espace_id = v_espace_etranger_id and user_id = v_user_id;

  perform set_config('app.test_user_id', v_user_id::text, true);
  perform set_config('app.test_espace_id', v_espace_etranger_id::text, true);
end $$;

set local role authenticated;
select set_config('request.jwt.claims',
    json_build_object('sub', current_setting('app.test_user_id'), 'role', 'authenticated')::text,
    true);

do $$
declare
  v_voit_etranger int;
begin
  select count(*) into v_voit_etranger
    from espaces where id = current_setting('app.test_espace_id')::uuid;

  if v_voit_etranger <> 0 then
    raise exception 'FAIL refuse une lecture inter-espace sur espaces : % ligne(s) visible(s) pour un espace dont l''utilisateur n''est pas membre', v_voit_etranger;
  end if;

  raise notice 'OK refuse une lecture inter-espace sur espaces';
end $$;

rollback;
