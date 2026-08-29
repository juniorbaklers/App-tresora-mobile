## Applies to
`supabase/**`, `lib/services/**`, `lib/providers/**` (tout fichier Dart qui
appelle `.from()`/`.rpc()` sur le client Supabase), tout SQL de migration.

## Standards
- MUST activer Row Level Security sur toute table qui porte des données
  d'un espace (tenant) — aucune exception, même pour une table
  « provisoire » ou purement interne.
- MUST écrire une policy RLS séparée par opération (SELECT/INSERT/UPDATE/
  DELETE) plutôt qu'une policy fourre-tout — c'est ce qui permet de repérer
  qu'un rôle intermédiaire a par erreur les mêmes droits qu'un rôle
  supérieur sur une opération précise.
- MUST vérifier, sur toute table qui porte des rôles/permissions, qu'un
  rôle intermédiaire (ex. `administrateur`) ne peut pas créer/modifier/
  supprimer une ligne portant le rôle le plus élevé (ex. `proprietaire`) —
  vérifier le `USING` (ligne existante) ET le `WITH CHECK` (ligne après
  modification) séparément, ce sont deux garde-fous distincts.
- MUST révoquer `EXECUTE` pour `anon` et `authenticated` sur toute fonction
  `SECURITY DEFINER` destinée uniquement à un job `pg_cron` — sinon
  n'importe qui, même non connecté, peut l'appeler directement via
  `/rest/v1/rpc/...` et elle s'exécute avec les droits du propriétaire,
  bypassant RLS sur tous les espaces de la base.
- MUST poser `SET search_path = public` (ou équivalent) sur toute fonction
  `SECURITY DEFINER`, et idéalement sur toute fonction utilisée dans une
  policy RLS.
- MUST NOT référencer `new.champ`/`old.champ` par branche `TG_TABLE_NAME`
  dans une fonction de trigger partagée entre plusieurs tables aux colonnes
  différentes — Postgres valide TOUTES les branches d'un `case` contre le
  type réel de l'enregistrement du déclenchement en cours, y compris celles
  jamais empruntées, et l'appel échoue avec
  `record "new" has no field "..."`. Utiliser `to_jsonb(new)->>'champ'` /
  `to_jsonb(old)->>'champ'` à la place — aucun nom de champ n'est validé à
  la compilation avec cette approche.
- MUST journaliser (`entrees_journal`/trigger `journaliser()`) toute table
  qui représente un mouvement d'argent dès sa création — pas ajoutée
  « plus tard » après un audit qui la trouve manquante.
- MUST tenir `supabase/schema_*.sql` synchronisé avec ce qui est réellement
  appliqué en base à chaque migration — dans le même commit. Un schéma
  local qui ne reflète pas l'état réel de la base est pire que pas de
  schéma local du tout : il ment avec autorité.
- SHOULD décider explicitement, pour toute nouvelle requête qui alimente un
  écran, si elle passe par le cache hors-ligne
  (`avecCacheHorsLigne`/`avecCacheHorsLigneFuture`) ou non — le défaut
  silencieux (pas de cache) casse l'écran à la moindre coupure réseau.
- SHOULD écrire la policy RLS d'une table dans la même migration que sa
  création, jamais dans une migration séparée « à faire après ».
