# Tests RLS — `supabase/tests/`

Tests d'isolation multi-tenant en SQL brut, pas pgTAP : cet environnement
n'a pas la CLI Supabase locale (`supabase test db` nécessite un stack
Postgres local avec l'extension pgTAP installée), et le projet n'a qu'un
seul projet Supabase distant. SQL brut + `mcp__Supabase__execute_sql` (ou
le SQL Editor du dashboard) suffit pour ce qu'on veut vérifier : est-ce
qu'un utilisateur voit des lignes qu'il ne devrait pas voir.

## Principe de chaque fichier

- Tout est encadré par `begin; ... rollback;` — rien ne doit jamais
  persister, même en cas de succès. Un test qui laisse des données de
  test dans la base n'est pas fiable pour une deuxième exécution.
- Les données nécessaires (ex. un "espace étranger") sont créées par le
  test lui-même, jamais supposées déjà présentes — les tests ne doivent
  pas dépendre de données réelles d'un compte en particulier.
- L'utilisateur "courant" impersonné est simplement le premier compte de
  `auth.users` — un seul suffit pour tester l'isolation, puisqu'on
  vérifie l'appartenance à `espace_membres` (ou l'absence d'appartenance),
  pas l'identité d'un utilisateur précis.
- Un échec fait échouer bruyamment (`RAISE EXCEPTION`), un succès affiche
  juste un `RAISE NOTICE 'OK ...'` et continue.

## Impersonation d'un rôle/utilisateur

```sql
set local role authenticated;
select set_config('request.jwt.claims',
    json_build_object('sub', '<uuid>', 'role', 'authenticated')::text,
    true);
```

**Important** : `set local role` et le `set_config` sur
`request.jwt.claims` doivent être des instructions **top-level** de la
transaction, pas à l'intérieur d'un bloc `do $$ ... $$`. Un changement de
rôle fait depuis l'intérieur d'un bloc PL/pgSQL ne s'applique pas de façon
fiable aux statements suivants du même bloc (vérifié empiriquement sur ce
projet — la belt-and-braces c'est de découper en plusieurs blocs séparés
par des variables de session `app.test_*` pour faire passer des valeurs
de préparation, calculées avec le rôle privilégié, vers la partie
impersonée).

## Piège : triggers `AFTER INSERT` et RETURNING

Un trigger `AFTER INSERT ... FOR EACH ROW` (ex. celui qui ajoute
automatiquement le créateur d'un espace dans `espace_membres`) modifie
bien la base avant que le statement d'insert ne se termine, mais son
effet **n'est pas visible** à une policy RLS évaluée dans la clause
`RETURNING` de ce même statement (confirmé empiriquement : une CTE
`WITH ... INSERT ... RETURNING` voit `est_membre_espace(id) = false`
juste après l'insert). Il est en revanche visible normalement à un
second statement séparé dans la même transaction. Ça a des conséquences
côté application : voir le commentaire sur `EspacesService.creer()`
(`lib/services/espaces_service.dart`) et l'entrée correspondante dans
`GAP-REPORT.md` §1.

## Exécuter un test

Copier le contenu du fichier dans le SQL Editor du dashboard Supabase, ou
via l'outil `mcp__Supabase__execute_sql` (project_id du projet
`App_tresors`, `ssceyciwrdslbubuwmnn`). Le `ROLLBACK` final garantit
qu'aucune trace ne persiste, succès ou échec.

## Fichiers

- `001_isolation_espaces.sql` — un membre d'un espace ne voit jamais un
  espace étranger (policy `espaces_lecture`).

À compléter : cotisations/paiements_cotisation/tranches, recettes/
depenses, abonnements, membres — une table par fichier, nommé par
comportement attendu plutôt que par nom de fonction interne
(`.claude/rules/tests.md`).
