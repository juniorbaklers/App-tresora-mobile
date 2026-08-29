---
name: implement-screen
description: "Implémente ou refond un écran Flutter à partir d'une maquette (canvas .dc.html, capture d'écran, description précise), conforme aux tokens de thème existants. Ne touche pas à la logique de données sauf demande explicite."
argument-hint: "[nom de l'écran ou référence de la maquette] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Write, Edit, Bash, Task, AskUserQuestion
model: sonnet
agent: mobile-engineer
---

Traduit une référence de design en écran Flutter réel, dans un projet qui a
déjà un système de tokens établi (`lib/theme/app_theme.dart`). Le travail
n'est pas d'inventer un style, c'est de faire correspondre deux sources de
vérité : la maquette (ce qui doit apparaître) et le thème existant (comment
c'est censé être codé).

## Phases
1. **Lire le thème** — chaque token de couleur/police disponible et ce à
   quoi il correspond sémantiquement. Si la maquette utilise une teinte
   sans équivalent, décider (avec l'utilisateur si le choix n'est pas
   évident) d'ajouter un token ou de la rapprocher d'un token existant.
2. **Localiser la référence** — si c'est un fichier `.dc.html`, grep les
   valeurs hex et les noms d'écran (souvent listés en fin de fichier) pour
   trouver le bloc précis plutôt que de tout parcourir en diagonale.
3. **Repérer la logique existante** — providers/services déjà utilisés par
   l'écran s'il existe. Le travail change la présentation, pas la
   récupération de données, sauf demande contraire explicite.
4. **Implémenter** — tokens existants, jamais de hex en dur. Si l'écran a
   des variantes (ex. dashboard église vs groupe), factoriser les widgets
   partagés et appliquer le même habillage aux variantes non montrées dans
   la maquette.
5. **Vérifier** — équilibrage accolades/parenthèses, existence de chaque
   symbole référencé (grep dans les fichiers modèles/services), chemins
   d'import. Si le SDK Flutter n'est pas installé dans l'environnement, le
   dire explicitement et recommander `flutter analyze` avant de merger —
   ne jamais prétendre avoir vérifié la compilation sinon.

## Sortie
Écran(s) modifié(s) + note explicite sur ce qui a été vérifié
automatiquement vs. ce qui reste à vérifier par `flutter analyze`/
`flutter run` avant de merger.
