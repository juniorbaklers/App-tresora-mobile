# Claude-Code-SaaS-Studio appliqué à Trésora — analyse et plan d'adaptation

Analyse du vrai repo [`evgenii-studitskikh/Claude-Code-SaaS-Studio`](https://github.com/evgenii-studitskikh/Claude-Code-SaaS-Studio)
(cloné et lu en entier — `.claude/agents/`, `.claude/rules/`, `.claude/hooks/`,
`.claude/skills/`, `.claude/templates/`), pas seulement les docs qui avaient
été uploadées dans ce repo (`Claude-Code-SaaS-Studio-main/` sur `main` ne
contient que README/CONVENTIONS/LICENSE + les specs `docs/superpowers/` —
pas le `.claude/` réel, qui n'avait jamais été commité ici).

## Ce que contient réellement le kit

12 agents en 2 tiers (3 directeurs Opus : `producer`, `product-director`,
`technical-director` ; 9 spécialistes Sonnet dont `database-engineer`,
`security-engineer`, `frontend-engineer`, `backend-engineer`,
`billing-engineer`, `qa-engineer`, `devops-engineer`, `ux-designer`,
`product-manager`), 23 skills organisées en 5 phases (Produit & UX →
Ingénierie → Facturation → Durcissement → Infra & lancement), 8 règles
scopées par chemin (`.claude/rules/*.md`), 4 hooks shell, 10 templates de
documents. Stack cible : Next.js (App Router) + Supabase + Stripe +
Tailwind/shadcn + Vercel.

Le principe qui traverse tout le kit : **ask → present options → user
decides → draft → approve**. Aucun agent ne finalise un artefact sans
validation explicite, avec un curseur d'intensité (`--review full|lean|solo`)
qui règle combien de portes d'approbation se déclenchent. C'est exactement
la discipline qu'on a suivie en début de cette session (5 questions posées
avant de toucher au code) — le kit formalise en process ce qu'on a déjà fait
une fois à la main.

## Ce qui se transpose presque tel quel

- **`.claude/rules/data.md` + agent `database-engineer` + skill
  `design-schema`.** C'est le cœur du kit le plus directement applicable :
  Trésora utilise déjà Supabase + RLS multi-tenant, exactement le terrain de
  cette règle. La règle « MUST enable Row Level Security on every table
  holding tenant data » et « MUST scope every query by tenant/org id; never
  trust a client-supplied tenant id » — c'est très exactement ce que l'audit
  RLS de cette session a dû aller vérifier à la main, policy par policy,
  faute d'un tel garde-fou posé dès le départ.
- **`.claude/rules/security.md` + agent `security-engineer` + skill
  `security-audit`.** Directement applicable. À enrichir avec les leçons
  propres à Trésora trouvées cette session : fonctions `SECURITY DEFINER`
  destinées à un job `pg_cron` mais accessibles en RPC public sans
  authentification, et l'escalade de privilèges sur une table de rôles où
  un niveau intermédiaire pouvait toucher le niveau le plus élevé.
- **`.claude/rules/tests.md`**, en particulier « MUST write an RLS/tenant-
  isolation test for every table holding tenant data » — ferme exactement
  le §2 du `GAP-REPORT.md` de ce repo (zéro test automatisé). À adopter
  comme règle du projet dès maintenant, indépendamment du reste du kit.
- **`.claude/hooks/validate-commit.sh`** (bloque les secrets/`.env` au
  commit) et **`validate-push.sh`** (avertit sur push vers `main`).
  Réutilisables sans changement — génériques git, aucune dépendance à la
  stack. Gain immédiat, zéro risque, ~10 minutes à installer.
- **Agents `producer` et `technical-director`** + le protocole
  ask→approve + le curseur d'intensité de revue. Générique, indépendant de
  la stack.
- **Skill `code-review`** — portable telle quelle (secrets, scoping tenant,
  couverture de tests, alerte sécurité).

## Ce qui doit être réécrit, pas copié

- **`frontend-engineer` + `.claude/rules/app.md`** sont du pur Next.js
  (« MUST use Server Components by default », `"use client"`/`"use server"`,
  `NEXT_PUBLIC_*`) — n'a aucun sens côté Flutter. Il faut un agent
  `mobile-engineer` + une règle `flutter.md` équivalents, qui capturent ce
  qu'on a appris cette session, pas ce que Next.js impose : jamais de
  couleur/police en dur dans un écran (tokens `AppColors`/`AppFonts`
  uniquement), toute nouvelle requête réseau qui alimente un écran doit
  explicitement décider si elle passe par le cache hors-ligne
  (`avecCacheHorsLigne`/`avecCacheHorsLigneFuture`) ou non — le défaut
  silencieux (pas de cache) est ce qui a laissé 3 écrans entiers plantés
  hors-ligne jusqu'à cette session.
- **`.claude/rules/auth.md`** cible des chemins Next.js purs
  (`middleware.*`, `app/**/layout.*`) — reste valable tel quel côté web,
  mais côté Flutter l'équivalent est l'écran `SplashScreen`/`AuthGate` : à
  documenter séparément, pas à copier.
- **`devops-engineer` + skill `setup-deploy`** sont 100% Vercel — aucun
  équivalent mobile dans le kit original (le kit n'a jamais été pensé pour
  livrer un binaire installable). À écrire de zéro un agent/skill
  `mobile-release-engineer` qui capture ce qu'on vient de découvrir dans
  cette session même : cet environnement n'a pas le SDK Android et
  `dl.google.com` y est bloqué par la politique réseau — la bonne réponse
  n'est pas de contourner le blocage, c'est d'utiliser le workflow GitHub
  Actions existant (`workflow_dispatch`) ; et si le téléchargement de
  l'artifact d'Action échoue lui aussi (stockage blob tiers bloqué),
  publier le build en asset de release GitHub à la place, qui passe par un
  domaine `github.com` presque toujours accessible.
- **`ux-designer` + skill `design-ui`** ciblent Tailwind/shadcn — sans
  objet côté Flutter (le design system de l'app mobile, ce sont des widgets
  Dart + les maquettes du canvas `.dc.html`). Reste valable tel quel côté
  web (`tresora-app` est bien du Next.js+Tailwind d'après son
  `REFACTOR-PLAN.md`).
- **`billing-engineer` + `.claude/rules/billing.md` + skills
  `setup-billing`/`design-pricing`** — à mettre de côté pour l'instant
  (décision producer de cette session : gratuit jusqu'à ce que la RLS soit
  auditée — fait), mais à garder intacts pour le jour où l'abonnement par
  espace sera activé : ils sont déjà écrits pour Stripe + Supabase, donc
  directement applicables le moment venu, pas à réécrire maintenant.

## Correction du 2026-08-29 : il n'y a pas deux frontends d'un même produit

Une hypothèse posée le 2026-08-28 (et le point #5 du plan ci-dessous, tel
qu'écrit à l'origine) supposait que `gestion-caisse-eglise` était le backend
du prototype web `tresora-app` — c'est-à-dire une deuxième interface du même
produit que l'app mobile, sur une base Supabase à faire converger.
**Vérifié faux le 2026-08-29** : `gestion-caisse-eglise`
(`juniorbaklers/gestion-caisse-eglise`) est un produit entièrement
différent — une app statique HTML/CSS/JS sans framework, un schéma
mono-caisse (`params`, `caisses`, `membres`, `mouvements`,
`compteur_recus`, `profils`, sans aucune notion d'`espaces`), un système de
rôles propre (Trésorier Principal/Adjoint/Lecture seule). Ce n'est pas
Trésora avec une autre interface, c'est un autre produit du même auteur sur
le même thème (trésorerie d'église).

Il n'y a donc pas de « backend partagé à faire converger » — cette
question n'existe pas. Ce que le kit original ne couvre effectivement pas,
en revanche, c'est le cas où Trésora aurait un jour un vrai second frontend
(le `tresora-app` Next.js/shadcn du `REFACTOR-PLAN.md`, s'il est construit)
sur le même backend `App_tresors` que le mobile — cette question-là reste
valide en théorie, mais n'est pas urgente : ce second frontend n'existe pas
encore comme code fonctionnel, seulement comme maquettes.

## Plan d'adaptation proposé, par ordre de valeur

1. **Socle sécurité/données** — adapter `data.md`, `database-engineer`,
   `security.md`, `security-engineer`, `tests.md` avec les leçons propres à
   Trésora. Déjà à ~90% aligné avec ce que cette session a fait à la main ;
   le formaliser évite de repartir de zéro à la prochaine table ajoutée.
2. **Hooks** — installer `validate-commit.sh` et `validate-push.sh` tels
   quels. Dix minutes, aucun risque, gain immédiat.
3. **`mobile-engineer` + `flutter.md`** — nouveau, capture les règles
   tokens de design / cache hors-ligne de cette session.
4. **`mobile-release-engineer`** — nouveau, formalise en skill réutilisable
   le pipeline CI → release GitHub qu'on vient de construire pour livrer
   l'APK.
5. ~~`design-schema` adapté au schéma partagé~~ — retiré du plan (voir
   correction ci-dessus : il n'y a pas de backend partagé à faire
   converger, `gestion-caisse-eglise` est un produit différent).
6. **Billing** — à activer tel quel, sans réécriture, le jour où
   l'abonnement par espace démarre.

Dis-moi par quel numéro tu veux que je commence — je peux écrire les
fichiers `.claude/` correspondants directement dans ce repo (et dans
`gestion-caisse-eglise` pour la partie web, une fois attaché).
