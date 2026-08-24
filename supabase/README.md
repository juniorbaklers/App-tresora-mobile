# Schéma Trésora v2 — modèle de données de tresora-app

Ce schéma est **indépendant** de celui de `gestion-caisse-eglise`. Il doit
tourner sur un **projet Supabase neuf et vide**, pas sur celui déjà utilisé
par le site web.

## Pourquoi un nouveau projet

`gestion-caisse-eglise` est pensé pour une seule église (caisses, mouvements
plats). `tresora-app` (le prototype Next.js dans le repo du même nom) est un
modèle bien plus riche : **espaces** multi-tenant (église, groupe,
association, ou perso), rôles par espace, cotisations payables en tranches,
événements, contributions inter-espaces, journal d'audit. Les deux modèles
ne peuvent pas cohabiter dans les mêmes tables — d'où un projet à part.

## Mise en route

1. Sur [supabase.com](https://supabase.com), crée un **nouveau projet**
   (vide, sans template)
2. Dans **SQL Editor**, exécute ces trois scripts **dans l'ordre**, chacun
   jusqu'au bout avant de passer au suivant :
   1. [`schema_1_types_tables.sql`](schema_1_types_tables.sql) — types
      énumérés + toutes les tables (espaces, membres, cotisations,
      tranches, recettes, dépenses, événements, contributions,
      notifications, journal d'audit, clôtures...)
   2. [`schema_2_triggers.sql`](schema_2_triggers.sql) — automatismes :
      création du profil à l'inscription, le créateur d'un espace en
      devient propriétaire, les tranches recalculent automatiquement le
      montant payé d'une cotisation, les versements inter-espaces
      recalculent le montant reçu d'une contribution
   3. [`schema_3_rls.sql`](schema_3_rls.sql) — Row Level Security : tout
      l'accès passe par la table `espace_membres` (qui est membre de quel
      espace, avec quel rôle)
3. Dans **Settings > API**, récupère l'**URL du projet** et la **clé
   publique (anon/publishable)**
4. Renseigne-les dans `lib/config/supabase_config.dart` de l'app Flutter
   (à la place des valeurs actuelles, qui pointent vers l'ancien projet
   gestion-caisse-eglise)
5. Dans **Database > Publications**, active le Realtime (`supabase_realtime`)
   pour les tables que l'app écoute en direct — au minimum : `espaces`,
   `espace_membres`, `membres`, `cotisations`, `paiements_cotisation`,
   `tranches`, `recettes`, `depenses`, `evenements`

## Rôles (par espace, table `espace_membres.role`)

| Rôle | Peut |
|---|---|
| `proprietaire` | Tout, y compris supprimer l'espace |
| `administrateur` | Tout sauf supprimer l'espace |
| `tresorier` | Recettes, dépenses, cotisations, membres, événements — pas les réglages de l'espace ni les rôles |
| `responsable` | Membres, cotisations, événements — pas l'argent (recettes/dépenses) |
| `membre` | Lecture seule |

Le créateur d'un espace en devient automatiquement `proprietaire`
(trigger). Les rôles suivants s'ajoutent ensuite via la table
`espace_membres` (pas encore d'écran d'invitation dans l'app mobile — à
faire).

## Ce qui reste à faire côté app Flutter

Ce schéma est prêt côté base, mais l'app Flutter actuelle (modèles,
services, providers, écrans) est encore branchée sur l'ancien modèle
caisses/mouvements de `gestion-caisse-eglise`. La reconnexion complète
vers ce nouveau modèle (espaces, cotisations en tranches, événements,
contributions) est un chantier séparé, pas encore commencé.
