# Trésora Mobile

Application mobile Flutter (Android/iOS) de gestion de trésorerie d'église —
réécriture native du projet web [`gestion-caisse-eglise`](https://github.com/juniorbaklers/gestion-caisse-eglise),
connectée à la **même base Supabase**. Une écriture saisie sur le mobile
apparaît en temps réel sur le site web, et inversement.

## Périmètre de cette v0.1 (socle fonctionnel)

- ✅ Authentification Supabase (email / mot de passe, inscription)
- ✅ Rôles (Trésorier Principal / Adjoint / Responsable de section / Lecture
  seule) — la barrière réelle est la Row Level Security côté base, l'app
  adapte juste l'interface en fonction du rôle
- ✅ Tableau de bord : total entrées / dépenses / solde de la Caisse
  Générale, soldes des caisses séparées (ex: ECODIM), graphique mensuel
- ✅ Mouvements (recettes/dépenses) : liste temps réel avec filtres, saisie,
  numéro de reçu généré automatiquement à la création d'une entrée
- ✅ Membres : registre nominatif, activation/désactivation

**Pas encore fait** (à porter depuis `app.js` dans une itération suivante) :
génération de reçus PDF, export Excel, sections & cotisations, clôture
d'exercice, gestion des caisses par le Trésorier Principal, mode hors-ligne.

## Stack

- Flutter 3.x / Dart 3.x
- [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) — auth,
  Postgres, RLS, synchronisation temps réel (mêmes tables que le site web)
- [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) — état
- [`fl_chart`](https://pub.dev/packages/fl_chart) — graphiques (équivalent
  mobile de Chart.js)

## Mise en route

1. Installe le [SDK Flutter](https://docs.flutter.dev/get-started/install)
2. Renseigne `lib/config/supabase_config.dart` avec l'URL et la clé publique
   (anon/publishable) du **même projet Supabase** que l'app web — Settings
   > API sur supabase.com. Les tables et politiques RLS sont déjà en place
   si tu as suivi le README de `gestion-caisse-eglise`.
3. `flutter pub get`
4. `flutter run` (émulateur, appareil connecté, ou `-d chrome` pour tester
   dans un navigateur)

## Architecture

```
lib/
├── config/          URL + clé Supabase
├── models/          Profil, Caisse, Membre, Mouvement, Role — reflètent schema.sql
├── services/         Appels Supabase (CRUD + flux temps réel par table)
├── providers/         État Riverpod (session, profil, caisses/membres/mouvements en stream)
├── utils/             Calcul des soldes (miroir de la logique de app.js), formatage FCFA/dates
├── widgets/            RoleGate (masque l'UI selon le rôle), StatCard
└── screens/
    ├── auth/           Connexion, inscription
    ├── home/            Navigation par onglets
    ├── dashboard/        Tableau de bord
    ├── mouvements/        Liste + formulaire de saisie
    ├── membres/            Liste + formulaire
    └── profil/              Infos du compte, déconnexion
```

## Rôles

Mêmes règles que l'app web (`schema.sql`, `schema_4_cloture.sql`,
`schema_6_sections_cotisations.sql`) :

- **Trésorier Principal** : accès complet
- **Trésorier Adjoint** : saisie/modification, pas de suppression
- **Responsable de section** : saisie limitée à la caisse de sa section
- **Lecture seule** : consultation uniquement

Le premier compte créé sur la base devient automatiquement Trésorier
Principal (trigger SQL côté Supabase, partagé avec l'app web).
