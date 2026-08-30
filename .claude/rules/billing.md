## Applies to
`supabase/**` (table `abonnements`), `docs/pricing.md`, tout futur code
Dart ou web touchant à la facturation/abonnement par espace.

## Standards
- MUST NOT laisser un rôle de l'espace (y compris `proprietaire`) écrire
  dans `abonnements` via une policy RLS applicative — la confirmation de
  paiement est manuelle (back-office, clé `service_role`) tant qu'aucun
  flux d'admin dédié n'existe. Un propriétaire qui pourrait confirmer son
  propre paiement pourrait se déclarer "actif" sans avoir réellement payé.
- MUST NOT écrire un paiement d'abonnement (ce que l'espace paie à
  Trésora) dans `entrees_journal`, `recettes` ou `depenses` — ce n'est pas
  un mouvement de trésorerie de l'organisation, ce serait mélanger
  l'argent de l'espace avec ce qu'il paie pour l'outil.
- MUST NOT intégrer Stripe ou tout autre rail carte bancaire sans décision
  producer explicite — le rail retenu (2026-08-30) est Mobile Money
  (Orange/MTN/Moov/Wave) à confirmation manuelle, cohérent avec le reste
  de l'app (voir `docs/pricing.md`). Le kit SaaS Studio (`billing-engineer`,
  skills `setup-billing`/`design-pricing`) cible Stripe par défaut : à
  adapter avant tout usage, pas à appliquer tel quel.
- MUST garder `prix_mensuel` comme une donnée (colonne `abonnements`),
  jamais une valeur en dur dans du code Dart, une policy SQL ou un écran —
  le prix doit rester ajustable sans migration.
- SHOULD garder la table `abonnements` vide de toute ligne réelle tant
  qu'aucun espace pilote n'utilise l'app en production (condition
  producer posée dans `GAP-REPORT.md` §3) — ne pas créer de ligne pour
  un espace de test/démo comme si c'était un vrai abonnement.
- SHOULD repasser par une décision producer explicite avant d'ajouter tout
  écran Flutter ou flux self-service de facturation (paiement,
  changement de statut) — ce n'est pas un choix technique.
