---
name: security-audit
description: "Audite la RLS, les fonctions SECURITY DEFINER et la surface RPC de Trésora contre les fuites inter-espaces et les escalades de privilèges. Produit un rapport de findings classés par sévérité."
argument-hint: "[--scope diff|full] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, mcp__Supabase__list_tables, mcp__Supabase__execute_sql, mcp__Supabase__get_advisors, AskUserQuestion, Task
model: sonnet
agent: security-engineer
---

Trouve et classe les risques de sécurité avant qu'ils n'atteignent la
production. Non-autonome : rapporte les findings et les correctifs
proposés, n'applique jamais de correctif sans accord explicite.

## Phases
1. **Périmètre** — par défaut, les tables/fonctions touchées par les
   migrations depuis le dernier audit (`list_migrations`). Sans point de
   départ clair, basculer sur un audit complet. Confirmer le périmètre
   avec l'utilisateur.
2. **Policies** — lire le texte exact de chaque policy RLS concernée
   (`pg_policies`), pas seulement `rls_enabled`. Vérifier `USING` et
   `WITH CHECK` séparément sur les tables de rôles/permissions.
3. **Fonctions `SECURITY DEFINER`** — corps réel + grants `EXECUTE`
   (`anon`/`authenticated`) pour chacune. Toute fonction non-trigger avec
   un grant `anon` est un point d'entrée RPC public à vérifier
   explicitement.
4. **`get_advisors`** (type `security`) — point de départ, pas liste
   complète.
5. **Classer les findings** — Critique (fuite/écriture inter-espace,
   argent réel) / Élevé (escalade de privilèges) / Moyen (fuite d'info
   limitée) / Faible-hygiène. Scénario d'exploitation concret pour chaque
   finding, pas juste « ceci semble risqué ».
6. **Verdict** — PASS (aucun Critique/Élevé ouvert) ou BLOCK (liste les
   bloquants). Met à jour `GAP-REPORT.md` avec chaque finding et son
   statut.

## Sortie
Findings classés + `GAP-REPORT.md` mis à jour. Ne modifie rien à la base
sans accord explicite du database-engineer et de l'utilisateur.
