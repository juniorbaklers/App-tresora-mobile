# Trésora Mobile

Application mobile Flutter (Android/iOS) de gestion de trésorerie
multi-espace — le pendant natif du prototype web `tresora-app` (Next.js,
même compte GitHub). Un utilisateur peut gérer plusieurs **espaces**
(église, groupe, association, ou perso) indépendants, chacun avec ses
propres membres, cotisations, recettes et dépenses.

Ce projet est **indépendant** de `gestion-caisse-eglise` (site web mono-
église) : base Supabase distincte, modèle de données différent. Voir
[`supabase/README.md`](supabase/README.md) pour la mise en route du backend.

## Périmètre actuel

- ✅ Authentification Supabase (email / mot de passe, inscription)
- ✅ Espaces : sélection, création (le créateur devient automatiquement
  propriétaire) ; un utilisateur peut appartenir à plusieurs
- ✅ Rôles **par espace** (propriétaire / administrateur / trésorier /
  responsable / membre) — la barrière réelle est la Row Level Security
  côté base, l'app adapte juste l'interface
- ✅ Tableau de bord : recettes/dépenses de l'espace courant, solde,
  graphique mensuel. Deux variantes selon le type d'espace, comme
  tresora-app (`DashboardEglise` / `DashboardGroupe`) : dîmes/offrandes pour
  une église, cotisation en cours (progression, payé/partiel/impayé),
  événements actifs, contributions demandées et derniers paiements pour un
  groupe/association/perso
- ✅ Recettes & Dépenses : liste temps réel, saisie. Recette : catégorie
  (filtrée par module), libellé, commentaire optionnel. Dépense :
  catégorie libre, description, bénéficiaire, mode de paiement, case
  "justificatif" — chaque écriture enregistre désormais qui l'a saisie
  (responsable), plus jamais vide
- ✅ Membres : registre nominatif par espace (prénom, nom, téléphone, email
  optionnel, fonction optionnelle), activation/désactivation
- ✅ Cotisations payables en plusieurs tranches : création (assignée à
  tous les membres actifs), ajout de membres après coup depuis le détail
  (icône dans l'AppBar, pour un membre arrivé après la création), suivi
  des versements par membre, montant payé/statut recalculés
  automatiquement côté base à chaque tranche.
  Écran "Paiement" (icône dans l'AppBar de Cotisations) pour encaisser
  directement la cotisation due d'un membre recherché par nom, sans passer
  par une cotisation précise — reprend `PaiementView` de tresora-app
- ✅ Fiche membre (au clic sur un membre) : coordonnées et historique
  financier (chaque cotisation qui le concerne avec son statut) — reprend
  `MembreDetail` de tresora-app (sans la carte membre/QR code, hors
  périmètre mobile)
- ✅ Événements : création (objectif, montant suggéré, période), liste avec
  barre de progression, détail avec enregistrement des contributions
  (montant collecté/nombre de participants mis à jour à chaque saisie).
  Si le contributeur saisi ne correspond à aucun membre existant de
  l'espace, l'app propose de l'ajouter au registre des membres
- ✅ Invitations : un propriétaire/administrateur invite par email depuis
  l'écran Membres (rôle choisi à l'envoi) ; l'invité voit ses invitations en
  attente sur l'écran de sélection d'espace et peut accepter (rejoint
  l'espace) ou refuser — accepter passe par la RPC `accepter_invitation`
  (sécurité définie côté base, l'invité n'étant pas encore membre)
- ✅ Contributions inter-espaces : un espace demande une somme à un autre
  (parmi les espaces que l'utilisateur gère aussi), accessible depuis
  l'icône dans l'AppBar du tableau de bord ; l'espace sollicité enregistre
  ses versements sans que le demandeur ne voie comment la somme a été
  réunie — montant reçu/statut recalculés côté base à chaque versement
- ✅ Notifications : boîte personnelle par utilisateur, alimentée
  automatiquement par des triggers côté base — accessible via la cloche du
  tableau de bord, avec badge du nombre de non lues. En temps réel :
  nouvelle demande de contribution, versement reçu, nouveau paiement de
  cotisation. En quotidien (pg_cron, 6h UTC) : cotisations en retard
  (statut recalculé automatiquement), événements démarrant sous 3 jours —
  au plus une notification par jour et par espace pour éviter le spam
- ✅ Journal d'audit : chaque création/modification/suppression de recette,
  dépense ou membre est tracée automatiquement côté base (qui, quand,
  ancienne/nouvelle valeur) — consultable en lecture seule depuis Réglages
- ✅ Clôtures (du dimanche ou de tout culte) : saisie de ce qui a été
  compté en caisse face à ce que les écritures de recette déclarent, écart
  calculé et justifiable, historique consultable depuis Réglages
- ✅ Réglages de l'espace : modifier nom/devise/solde initial (propriétaire/
  administrateur), gérer le rôle de chaque membre ou le retirer de
  l'espace — plus besoin de passer par Supabase pour ça
- ✅ Rôles et permissions : page de référence en lecture seule listant ce
  que chaque rôle peut faire (matrice des permissions), accessible depuis
  Réglages — reprend `/espace/[espaceId]/roles` de tresora-app ; la
  barrière réelle reste la RLS côté base
- ✅ Identité visuelle "pile de carnets" sur l'écran de sélection d'espace :
  chaque carte d'espace est présentée comme un carnet de comptes, avec
  deux feuillets décalés en arrière-plan et une tranche colorée (motif de
  tissage) qui varie d'un espace à l'autre
- ✅ Rapports : génération d'un PDF de trésorerie (recettes/dépenses par
  catégorie) sur une période choisie, partageable directement depuis le
  téléphone — accessible depuis l'icône PDF de l'écran Recettes & Dépenses
- ✅ Mode hors-ligne (lecture seule) : les listes principales (espaces,
  membres, cotisations, recettes/dépenses, événements, notifications,
  journal, clôtures) restent consultables sans connexion grâce à un cache
  local des dernières données reçues ; un bandeau discret l'indique. Pas
  de saisie hors-ligne — les formulaires nécessitent toujours le réseau.
- ✅ Écran de démarrage animé (pastille, nom, motif de tissage qui se
  dessine progressivement, ~2,8s) avant de rejoindre l'écran de connexion
  ou de sélection d'espace.
- ✅ Modules par espace : chaque espace n'active que les fonctionnalités
  dont il a besoin (Membres, Cotisations, Événements, Dîmes, Offrandes,
  Dons, Contributions... Rapports toujours actif) — les onglets de
  navigation et les cartes du tableau de bord s'adaptent en conséquence.
  Dîmes/Offrandes sont activées par défaut uniquement pour les espaces de
  type église, mais restent activables pour n'importe quel type ; tout se
  règle depuis Réglages → Modules. Reprend le système `ModuleKey` de
  tresora-app (src/lib/types.ts, src/lib/nav.ts) : les catégories proposées
  à la saisie d'une recette (Dîme/Offrande vs Cotisation/Activité) et
  l'accès aux Clôtures depuis Réglages suivent aussi les modules Dîmes/
  Offrandes actifs sur l'espace, comme sur l'app web.

## Performance / connexions temps réel

Les écrans qui agrègent sur *toutes* les cotisations d'un espace (Paiement,
tableau de bord des espaces non-église, fiche membre) ouvraient auparavant
un flux Supabase Realtime **par cotisation** (et, pour "derniers paiements"
du tableau de bord, un flux **par paiement**) — potentiellement des dizaines
de connexions temps réel simultanées rien que pour afficher un écran,
d'où une lenteur perceptible surtout sur réseau mobile. Ils utilisent
maintenant `paiementsEspaceProvider`/`tranchesCotisationProvider`
(`lib/providers/data_providers.dart`) : une seule requête groupée
(`.inFilter(...)`) au lieu d'un flux par élément. Les écrans qui affichent
le détail d'une cotisation ou d'un versement précis gardent leur flux temps
réel individuel (peu nombreux, mise à jour instantanée utile).

Les polices de marque (Fraunces, Plus Jakarta Sans, IBM Plex Mono) ne sont
pas encore embarquées comme assets locaux ; `google_fonts` tenterait sinon
de les télécharger au premier affichage de chaque écran à chaque lancement
(cache froid), bloquant le rendu sur une requête réseau. `main.dart` désactive
ce téléchargement à l'exécution (`GoogleFonts.config.allowRuntimeFetching =
false`) — l'app retombe sur la police système en attendant un vrai
embarquement des `.ttf`, mais ne bloque plus jamais sur un appel réseau pour
afficher du texte.

## Stack

- Flutter 3.x / Dart 3.x
- [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) — auth,
  Postgres, RLS, synchronisation temps réel
- [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) — état
- [`fl_chart`](https://pub.dev/packages/fl_chart) — graphiques
- [`google_fonts`](https://pub.dev/packages/google_fonts) — Fraunces /
  Plus Jakarta Sans / IBM Plex Mono (identité "tissage" de tresora-app)
- [`pdf`](https://pub.dev/packages/pdf) + [`printing`](https://pub.dev/packages/printing) —
  génération et partage des rapports de trésorerie
- [`shared_preferences`](https://pub.dev/packages/shared_preferences) +
  [`connectivity_plus`](https://pub.dev/packages/connectivity_plus) —
  cache local et détection réseau pour le mode hors-ligne (lecture seule)

## Récupérer un APK sans installer Flutter

Un workflow GitHub Actions (`.github/workflows/build-apk.yml`) compile un
APK release à chaque push touchant le code Flutter : onglet **Actions** du
repo → dernier run → section **Artifacts** → `tresora-mobile-apk`. Cet APK
pointe vers les identifiants Supabase présents dans le dépôt au moment du
build.

## Mise en route (développement local)

1. Installe le [SDK Flutter](https://docs.flutter.dev/get-started/install)
2. Crée le backend en suivant [`supabase/README.md`](supabase/README.md)
   (projet Supabase dédié + les 3 scripts SQL)
3. Renseigne `lib/config/supabase_config.dart` avec l'URL et la clé
   publique de ce projet
4. `flutter pub get`
5. `flutter run`

## Architecture

```
lib/
├── config/            URL + clé Supabase
├── models/             Profil, Espace (+ModuleEspace), Membre, Cotisation/PaiementCotisation/Tranche,
│                        Recette/Depense, Evenement, Invitation, Contribution,
│                        NotificationTresora, EntreeJournal, Cloture, MembreCompte, Role —
│                        reflètent supabase/schema_1_types_tables.sql
├── services/            Appels Supabase (CRUD + flux temps réel par table)
├── providers/            État Riverpod : session, mes espaces, espace courant + rôle,
│                          données scopées à l'espace sélectionné
├── theme/                 Palette "tissage", typographie de marque
├── utils/                  Formatage FCFA/dates, cache hors-ligne (avecCacheHorsLigne)
├── widgets/                 RoleGate (masque l'UI selon le rôle dans l'espace courant),
│                             StatCard, BandeTissee (motif signature), BandeauHorsLigne
└── screens/
    ├── splash/               Écran de démarrage animé (premier écran, avant AuthGate)
    ├── auth/                Connexion, inscription
    ├── espaces/               Sélection / création d'espace (premier écran après connexion)
    ├── home/                   Navigation par onglets
    ├── dashboard/               Tableau de bord de l'espace courant
    ├── tresorerie/               Recettes/dépenses : liste + formulaire
    ├── cotisations/               Liste, création, détail (suivi des tranches par membre)
    ├── evenements/                  Liste (progression), création, détail (contributions)
    ├── contributions/                Envoyées/reçues, création, détail (versements), accessible depuis le tableau de bord
    ├── notifications/                 Boîte personnelle, accessible depuis la cloche du tableau de bord
    ├── rapports/                      Génération/partage PDF, accessible depuis Recettes & Dépenses
    ├── membres/                    Liste + formulaire + invitations (envoi, annulation)
    ├── reglages/                    Réglages de l'espace + rôles des membres, accessible depuis Profil
    ├── journal/                      Journal d'audit (lecture seule), accessible depuis Réglages
    ├── clotures/                     Liste + saisie d'une clôture, accessible depuis Réglages
    └── profil/                      Identité, espace courant + rôle, déconnexion
```

## Rôles (par espace)

| Rôle | Peut |
|---|---|
| `proprietaire` | Tout, y compris supprimer l'espace |
| `administrateur` | Tout sauf supprimer l'espace |
| `tresorier` | Recettes, dépenses, cotisations, membres — pas les réglages de l'espace |
| `responsable` | Membres, cotisations — pas l'argent |
| `membre` | Lecture seule |

Le créateur d'un espace en devient automatiquement `proprietaire` (trigger
SQL). Les membres suivants rejoignent l'espace par invitation par email
(écran Membres) et leur rôle se gère ensuite depuis Réglages.
