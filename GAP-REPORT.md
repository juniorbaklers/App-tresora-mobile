# GAP-REPORT — Trésora Mobile

Dernière mise à jour : 2026-08-28. Reconstitué après perte du brouillon précédent
(conteneur de session éphémère recyclé avant commit) ; complété avec un audit RLS
réel sur le projet Supabase de production.

## 1. RLS — audité le 2026-08-28, corrections critiques appliquées

Projet audité : `App_tresors` (`ssceyciwrdslbubuwmnn`, eu-west-3), celui que l'app
mobile utilise réellement (`lib/config/supabase_config.dart`). RLS est activée sur
les 21 tables `public.*`, ce qui n'avait jamais été vérifié depuis l'écriture
initiale malgré l'ajout d'une dizaine de tables. L'audit a trouvé et corrigé
directement en base (migration `audit_rls_durcissement`) :

- **[CRITIQUE — corrigé] RPC cross-tenant accessible sans authentification.**
  `notifier_cotisations_en_retard()` et `notifier_evenements_bientot()` sont
  `SECURITY DEFINER`, `RETURNS void` (donc appelables directement, contrairement
  aux fonctions `RETURNS trigger`), et avaient `EXECUTE` accordé à `anon` **et**
  `authenticated`. N'importe qui, même non connecté, pouvait les invoquer via
  `/rest/v1/rpc/...` : elles écrivent dans `paiements_cotisation` et
  `notifications` pour **tous les espaces de la base**, sans aucune vérification
  d'appartenance — contournement total du cloisonnement multi-tenant. Seul le job
  `pg_cron` "notifications-quotidiennes" (06:00, exécuté en tant que `postgres`)
  doit les déclencher. → `EXECUTE` révoqué pour `anon`/`authenticated`, confirmé
  sans impact sur l'app (elle ne les appelle jamais directement) ni sur le cron
  (qui s'exécute avec les droits du propriétaire, indépendant des grants).

- **[CRITIQUE — corrigé] Escalade de privilèges sur `espace_membres`.** Les
  policies INSERT/UPDATE/DELETE de la table qui porte les rôles utilisaient
  `peut_administrer()`, qui autorise aussi bien `'proprietaire'` que
  `'administrateur'`. Un simple `'administrateur'` pouvait donc s'auto-promouvoir
  `'proprietaire'`, rétrograder ou supprimer le vrai propriétaire, ou ajouter un
  compte complice comme co-propriétaire — via l'app (`changerRole` dans
  `espaces_service.dart`) ou un appel direct à l'API REST. → nouvelle fonction
  `peut_gerer_role_membre()` : seul un `'proprietaire'` peut désormais
  créer/modifier/supprimer une ligne dont le rôle actuel **ou** visé est
  `'proprietaire'`. Le reste de la hiérarchie (administrateur/trésorier/
  responsable/membre) reste géré par les admins comme avant — aucune régression
  fonctionnelle attendue.

- **[MOYEN — corrigé] Fuite de PII inter-espaces sur `profils`.** La policy
  SELECT n'exigeait que `auth.role() = 'authenticated'` : n'importe quel
  utilisateur connecté pouvait lire nom complet + email de **tous** les
  utilisateurs de la base, y compris des personnes d'espaces sans aucun rapport.
  → restreint aux profils des utilisateurs partageant au moins un espace commun
  (+ soi-même).

- **[HYGIÈNE — corrigé] 9 fonctions `RETURNS trigger`** (`gerer_nouvel_espace`,
  `gerer_nouvel_utilisateur`, `journaliser`, `notifier_nouveau_paiement`,
  `notifier_nouvelle_contribution`, `notifier_versement_contribution`,
  `recalculer_contribution`, `recalculer_evenement`,
  `recalculer_paiement_cotisation`) avaient `EXECUTE` accordé à `anon`/
  `authenticated` sans raison — Postgres refuse déjà leur appel direct hors
  contexte trigger, mais elles n'ont rien à faire dans la surface d'API
  publique. → `EXECUTE` révoqué.

- **[HYGIÈNE — corrigé] `search_path` mutable** sur `peut_gerer`,
  `peut_administrer`, `peut_gerer_membres` (signalé par l'advisor Supabase,
  ces fonctions sont utilisées dans quasi toutes les policies RLS). → `SET
  search_path = public` ajouté aux trois.

- **[HYGIÈNE — corrigé] `accepter_invitation`** : `EXECUTE` retiré à `anon`
  (la fonction exige `auth.uid()`/`auth.jwt()`, aucun appelant anonyme
  légitime ; l'app l'appelle déjà authentifiée).

- **[OUVERT — réglage dashboard, pas une migration] Protection mot de passe
  compromis désactivée** (vérification HaveIBeenPwned). À activer dans
  Authentication → Policies sur le dashboard Supabase.

- **[OUVERT — décision produit, pas un bug] Espace sans propriétaire.** Le
  nouveau garde-fou empêche un non-propriétaire de toucher une ligne
  `'proprietaire'`, mais rien n'empêche aujourd'hui un unique propriétaire de se
  rétrograder lui-même et de laisser l'espace sans propriétaire. À trancher si
  ça doit être bloqué (ex. exiger qu'il reste toujours au moins un
  `'proprietaire'`) une fois l'écran Rôles retravaillé.

- **[À surveiller, non corrigé] `notifications_creation`** autorise tout
  `'administrateur'`/`'proprietaire'`/`'tresorier'` à insérer une notification
  pour n'importe quel `user_id`, y compris hors de l'espace. Risque faible
  (abus intra-espace par un admin déjà de confiance), pas traité dans cette
  passe — à revisiter si le produit expose un jour la messagerie aux membres
  simples.

**Architecture backend constatée pendant l'audit — corrigé le 2026-08-29 :**
l'app mobile pointe sur le projet Supabase `App_tresors` (`ssceyciwrdslbubuwmnn`),
distinct du projet `gestion-caisse-eglise` (`oilvgouoipdrripczigj`). Une
hypothèse du 2026-08-28 supposait que ce second projet était le backend du
prototype web `tresora-app` (même produit que l'app mobile, juste une autre
interface) et recommandait une convergence vers un backend unique.
**C'était faux.** Vérification faite le 2026-08-29 : `gestion-caisse-eglise`
est un produit entièrement différent — une app statique HTML/CSS/JS
(`juniorbaklers/gestion-caisse-eglise`, sans framework, aucune notion
multi-espace), avec son propre schéma (`params`, `caisses`, `membres`,
`mouvements`, `compteur_recus`, `profils` — pas d'`espaces`/`espace_membres`)
et son propre système de rôles (Trésorier Principal/Adjoint/Lecture seule).
Il gère une seule caisse d'église, pas plusieurs organisations dans une base
partagée. Rien à converger : ce n'est pas une deuxième interface de Trésora,
donc pas de décision de backend partagé à trancher. Le point ouvert, si
pertinent, est un choix produit distinct — garder les deux produits séparés
ou les fusionner un jour — pas un chantier d'infrastructure.

## 2. Zéro test automatisé

`test/` est vide dans tout le dépôt. Pas de couverture sur les calculs
financiers (tranches, cotisations, clôtures), les triggers de recalcul, ni les
policies RLS elles-mêmes (pgTAP ou équivalent serait idéal pour ces dernières
vu ce qui a été trouvé en §1). Pas traité dans cette passe — recommandé
d'ajouter des tests au fil de l'eau sur ce qui est touché plutôt qu'un chantier
séparé.

## 3. Journal d'audit incomplet — comblé le 2026-08-28

`entrees_journal` (trigger `journaliser()`) ne couvrait que recettes/dépenses/
membres. Cotisations, tranches, contributions et clôtures — pourtant les
mouvements d'argent les plus sensibles — n'y apparaissaient pas.

Corrigé (migrations `journal_audit_cotisations_contributions_clotures` puis
`journal_audit_fix_record_field_access`) : `journaliser()` calcule maintenant
l'`espace_id` via les jointures nécessaires pour les tables qui n'ont pas de
colonne `espace_id` directe (`paiements_cotisation`, `tranches`,
`contribution_versements` — remontée via `cotisation_id`/
`paiement_cotisation_id`/`contribution_id`), et 6 triggers `journal_*` ont été
ajoutés sur `cotisations`, `paiements_cotisation`, `tranches`, `contributions`,
`contribution_versements`, `clotures`.

Piège rencontré en cours de route, pour référence : une fonction plpgsql
partagée entre triggers de tables différentes ne peut pas faire `new.champ`/
`old.champ` par branche selon `TG_TABLE_NAME` — Postgres valide TOUTES les
branches d'un `case` contre le type réel de l'enregistrement du déclenchement
en cours, y compris les branches non empruntées, et fait échouer la fonction
("record "new" has no field ..."). Remplacé par un accès JSONB dynamique
(`to_jsonb(new)->>'champ'`), qui ne référence aucun nom de champ au moment de
la compilation. Testé en transaction avec rollback sur les 4 domaines
(tranches + cascade paiements_cotisation, clôtures, contributions +
contribution_versements) avant validation.

## 4. Mode hors-ligne ne couvre pas les paiements de cotisation — comblé le 2026-08-28

Écrans Paiement rapide / Dashboard groupe / Fiche membre : aucun cache
`shared_preferences` en secours si `connectivity_plus` signale une coupure.

Corrigé : `OfflineCache`/`avecCacheHorsLigne` existait déjà pour les flux
temps réel (cotisations, recettes, dépenses...) mais pas pour les deux
requêtes ponctuelles (`Future`, pas `Stream`) qui alimentent ces 3 écrans —
`PaiementsCotisationService.fetchPourCotisations` (Paiement rapide, Fiche
membre, via `paiementsEspaceProvider`) et `TranchesService.fetchPourPaiements`
(« derniers paiements » du dashboard groupe, via `tranchesCotisationProvider`).
Ajouté `avecCacheHorsLigneFuture` dans `cache_hors_ligne.dart` (même principe :
réseau si possible, sinon dernier instantané local, jamais d'erreur remontée à
l'écran) et branché les deux méthodes dessus. Au passage, le flux
`PaiementsCotisationService.streamPaiements` (dont dépend directement le
tableau de bord groupe pour ses totaux) n'était lui non plus jamais passé par
le cache — corrigé de la même façon que `streamCotisations`, sinon
`tranchesCotisationProvider` n'aurait jamais eu d'ids à chercher hors-ligne
puisqu'il dépend de ce flux en amont.

## 5. Pas de design system centralisé

Spacing codé en dur à travers les écrans, thème sombre jamais vérifié
visuellement. Traité dans le cadre de la refonte design (écran d'accueil +
dashboard en priorité, cf. décisions producer ci-dessous).

## Décisions producer validées le 2026-08-28

1. Gaps de sécurité (RLS) traités en premier — fait pour les points critiques
   ci-dessus. Refonte design démarre en parallèle, sans merge avant fermeture
   des gaps restants (tests, journal d'audit, offline cotisations).
2. Design : écran d'accueil + dashboard en priorité absolue.
3. Monétisation : gratuit pour l'instant, abonnement par espace une fois la
   RLS auditée (fait) et après un premier usage réel sur des espaces pilotes.
4. `tresora-app` (web) / `app-tresora-mobile` : codebases séparées, un seul
   backend Supabase partagé visé — migration réelle à planifier (les deux
   projets Supabase existants sont aujourd'hui distincts, cf. §1).
5. Lancement : type d'espace **église** en priorité (module le plus mature).
   Date cible non fixée par le producer — 4 à 6 semaines proposées comme
   ordre de grandeur pour un pilote soft, à confirmer.
