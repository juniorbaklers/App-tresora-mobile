# Facturation & pricing — structure posée le 2026-08-30

Ce document capture les décisions producer prises pour l'abonnement par
espace, et l'état réel de ce qui est construit. À relire avant toute
activation réelle de la facturation.

## Décisions

1. **Stade du projet** : aucun espace pilote réel n'utilise l'app en
   production à ce jour. Cette session pose donc uniquement la
   *structure* (schéma Supabase + rules) — aucun écran Flutter, aucun
   paiement réel câblé. Rien n'est facturé.
2. **Rail de paiement** : Mobile Money (Orange Money / MTN Money / Moov
   Money / Wave), confirmation manuelle. Le trésorier paie l'abonnement
   comme il paie déjà tout le reste dans l'app (cf. le flux d'encaissement
   cotisation/événement), et une personne côté Trésora confirme
   manuellement la réception côté back-office. Pas d'intégration API
   opérateur : ces API ne sont pas ouvertes en libre-service comme Stripe
   l'est pour les cartes bancaires.
   - Stripe (le défaut du kit SaaS Studio / `billing-engineer`) est
     explicitement écarté pour l'instant : il suppose une carte bancaire,
     ce qui ne correspond pas au public réel de l'app.
3. **Prix de départ** : essai gratuit de 30 jours, puis 5 000 F/mois par
   espace, palier unique quel que soit le type d'espace (église, groupe,
   association). Stocké comme donnée (`abonnements.prix_mensuel`), pas en
   dur dans le code — ajustable sans migration.
4. **Portée actuelle** : uniquement la structure (schéma + rule
   `.claude/rules/billing.md`). Pas d'écran "Mon abonnement" côté mobile
   pour l'instant — rien à afficher tant que personne n'est facturé.

## Ce qui existe déjà côté base

Table `abonnements` (migration `abonnements_par_espace`,
2026-08-30) :

| Colonne | Rôle |
|---|---|
| `espace_id` | un espace = au plus un abonnement (unique) |
| `statut` | `essai` / `actif` / `expire` / `suspendu` |
| `prix_mensuel` | 5 000 par défaut, XOF |
| `date_debut_essai` / `date_fin_essai` | essai 30 jours par défaut |
| `derniere_confirmation_paiement` / `confirme_par` / `reference_paiement` | trace de la confirmation manuelle |
| `notes` | libre, pour le back-office |

RLS : lecture réservée à `proprietaire`/`administrateur` de l'espace
(`peut_administrer`). Aucune policy d'écriture — la table n'est
modifiable que par la clé `service_role` (back-office), jamais par
l'app. Testé en transaction+rollback : le propriétaire lit sa propre
ligne, un tiers n'en voit aucune, et même le propriétaire ne peut pas
insérer une ligne (RLS le bloque, comme voulu — voir
`.claude/rules/billing.md`).

## Ce qui reste à faire le jour de l'activation réelle

Pas construit maintenant, à faire quand le premier usage pilote réel
existe (condition posée dans `GAP-REPORT.md` §3) :

- Créer la ligne `abonnements` pour chaque espace pilote (manuellement,
  ou via un petit outil back-office — pas encore décidé).
- Un flux pour que le trésorier signale "j'ai payé" (référence de
  transaction) sans pouvoir s'auto-confirmer `actif`.
- Un écran de confirmation côté back-office (qui reste à définir : outil
  interne, ou futur `tresora-app` web une fois construit).
- Décider si/quand un `pg_cron` doit faire passer `essai` → `expire`
  automatiquement à `date_fin_essai`, et ce qui se passe pour un espace
  `expire` (lecture seule ? blocage ? période de grâce ?) — pas tranché.
- Un écran Flutter "Mon abonnement" (Profil > Abonnement) en lecture
  seule, une fois qu'il y a quelque chose de réel à y afficher.
