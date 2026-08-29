---
name: design-schema
description: "Concevoir/modifier des tables Postgres, des relations, des policies RLS et le scoping multi-espace pour Supabase. Produit une migration prête à appliquer. Validation utilisateur avant tout apply_migration."
argument-hint: "[--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, mcp__Supabase__list_tables, mcp__Supabase__execute_sql, mcp__Supabase__apply_migration, Task, AskUserQuestion
model: sonnet
agent: database-engineer
---

Traduit un besoin fonctionnel en schéma Postgres concret avec policies RLS,
scoping multi-espace, et migration Supabase prête à appliquer. Non-
autonome : le schéma complet est présenté et approuvé avant tout
`apply_migration`.

## Phases
1. **Contexte** — lire `supabase/schema_*.sql` (l'état connu) et
   `list_tables` (l'état réel en base — les deux peuvent diverger, voir
   `.claude/rules/data.md`). Si divergence trouvée, la signaler avant de
   continuer.
2. **Tables et relations** — proposer chaque table (colonnes, clés, index),
   en notant explicitement lesquelles portent un `espace_id` direct et
   lesquelles nécessitent une jointure pour le résoudre (comme
   `paiements_cotisation`/`tranches`/`contribution_versements`
   aujourd'hui). Présenter pour revue.
3. **Policies RLS** — pour chaque table, une policy séparée par opération
   (SELECT/INSERT/UPDATE/DELETE), avec le texte de la condition expliqué
   en clair. Vérifier explicitement le cas d'un rôle intermédiaire
   touchant une ligne de rôle supérieur si la table porte des rôles.
4. **Cas limites** — index manquants sur clés étrangères, implications des
   cascades de suppression, fonctions `SECURITY DEFINER` nécessaires (avec
   `SET search_path` et grants `EXECUTE` explicitement décidés, jamais
   laissés par défaut à `anon`+`authenticated`).
5. **Écrire la migration** — SQL prêt, plus mise à jour de
   `supabase/schema_*.sql` dans le même lot. Ne JAMAIS appeler
   `apply_migration` sans validation explicite.
6. **Appliquer (si approuvé)** — `apply_migration`, puis tester en
   transaction avec rollback (voir la skill `security-audit`), puis
   reporter le résultat.

## Sortie
Migration appliquée (si approuvée) + `supabase/schema_*.sql` à jour +
entrée `GAP-REPORT.md` mise à jour si ça ferme un écart existant.
