## Applies to
`test/**`, `**/*_test.dart`, `supabase/tests/**` (si des tests pgTAP sont
ajoutés un jour).

## Standards
- MUST écrire un test d'isolation multi-tenant pour toute nouvelle table
  qui porte des données d'espace — au minimum : un utilisateur de l'espace
  A ne doit rien pouvoir lire/écrire sur les données de l'espace B.
- MUST tester toute nouvelle fonction de trigger en transaction avec
  `rollback` avant de considérer la migration validée — un `apply_migration`
  qui retourne `success: true` ne prouve que la validité syntaxique du SQL,
  pas que le comportement est correct.
- SHOULD ajouter les tests au fil de l'eau sur ce qui est modifié plutôt
  que d'attendre un chantier de rattrapage séparé — `test/` vide depuis le
  début du projet ne s'est jamais rattrapé en une fois nulle part, et ne se
  rattrapera pas plus ici.
- SHOULD nommer les tests par comportement attendu (« refuse une lecture
  inter-espace »), pas par nom de fonction interne.
