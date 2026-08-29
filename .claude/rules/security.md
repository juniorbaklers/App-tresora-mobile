## Applies to
`**` (transversal), avec emphase sur `supabase/**`, `lib/config/**`,
`.github/workflows/**`.

## Standards
- MUST NOT exposer une fonction `SECURITY DEFINER` en RPC public
  (`grant execute ... to anon, authenticated`) sans avoir vérifié qu'elle
  filtre explicitement sur l'espace/l'utilisateur appelant — une fonction
  pensée pour un job `pg_cron` n'a par défaut aucun filtre de ce genre, et
  `SECURITY DEFINER` veut dire qu'elle bypass RLS pour tout le monde.
- MUST NOT committer une clé `service_role` Supabase où que ce soit dans le
  repo (code Dart/TypeScript, fichier de config, workflow CI) — seule la
  clé publique `anon` a sa place côté client, mobile ou web.
- MUST vérifier, sur toute table qui stocke des profils/utilisateurs, que
  la policy SELECT ne permet pas à un utilisateur connecté de lire les
  données de tous les autres utilisateurs de la base, y compris ceux
  d'espaces sans aucun rapport avec le sien.
- MUST NOT modifier un fichier `.github/workflows/*.yml` et le pousser sans
  le signaler explicitement à l'utilisateur avant de pousser — un
  changement de pipeline CI/CD est un changement à risque, même petit et
  réversible.
- SHOULD, avant de conclure qu'une policy RLS est correcte parce qu'elle
  « existe déjà », relire son texte exact (`qual`/`with_check` dans
  `pg_policies`) plutôt que de se fier à son nom ou à `rls_enabled: true`.
- SHOULD auditer la RLS (agent `security-engineer` / skill
  `security-audit`) après toute migration qui touche une table, une
  policy, ou une fonction `SECURITY DEFINER` — pas seulement une fois au
  lancement du projet. La RLS de ce projet est restée fausse sur plusieurs
  tables pendant des semaines simplement parce que personne n'a repensé à
  la réauditer après l'ajout de nouvelles tables.
