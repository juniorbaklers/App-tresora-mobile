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
  graphique mensuel
- ✅ Recettes & Dépenses : liste temps réel, saisie
- ✅ Membres : registre nominatif par espace, activation/désactivation
- ✅ Cotisations payables en plusieurs tranches : création (assignée à
  tous les membres actifs), suivi des versements par membre, montant
  payé/statut recalculés automatiquement côté base à chaque tranche

**Pas encore fait** (modèle déjà prêt côté base, voir
`supabase/schema_1_types_tables.sql`) : événements, contributions
inter-espaces, notifications, journal d'audit affiché dans l'app, clôtures,
rapports/exports, invitations, gestion des rôles depuis l'app (à faire
directement dans Supabase pour l'instant), identité visuelle "pile de
carnets" sur l'écran de sélection d'espace, mode hors-ligne.

## Stack

- Flutter 3.x / Dart 3.x
- [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) — auth,
  Postgres, RLS, synchronisation temps réel
- [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) — état
- [`fl_chart`](https://pub.dev/packages/fl_chart) — graphiques
- [`google_fonts`](https://pub.dev/packages/google_fonts) — Fraunces /
  Plus Jakarta Sans / IBM Plex Mono (identité "tissage" de tresora-app)

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
├── models/             Profil, Espace, Membre, Cotisation/PaiementCotisation/Tranche,
│                        Recette/Depense, Role — reflètent supabase/schema_1_types_tables.sql
├── services/            Appels Supabase (CRUD + flux temps réel par table)
├── providers/            État Riverpod : session, mes espaces, espace courant + rôle,
│                          données scopées à l'espace sélectionné
├── theme/                 Palette "tissage", typographie de marque
├── utils/                  Formatage FCFA/dates
├── widgets/                 RoleGate (masque l'UI selon le rôle dans l'espace courant),
│                             StatCard, BandeTissee (motif signature)
└── screens/
    ├── auth/                Connexion, inscription
    ├── espaces/               Sélection / création d'espace (premier écran après connexion)
    ├── home/                   Navigation par onglets
    ├── dashboard/               Tableau de bord de l'espace courant
    ├── tresorerie/               Recettes/dépenses : liste + formulaire
    ├── cotisations/               Liste, création, détail (suivi des tranches par membre)
    ├── membres/                    Liste + formulaire
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
SQL). Les rôles suivants s'ajoutent pour l'instant directement dans la
table `espace_membres` sur Supabase — pas encore d'écran d'invitation dans
l'app.
