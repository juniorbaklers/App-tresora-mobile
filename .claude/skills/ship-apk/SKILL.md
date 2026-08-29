---
name: ship-apk
description: "Construit un APK Trésora via CI et le livre — en pièce jointe si sous ~30 Mio, sinon en lien de téléchargement direct. Utiliser quand on demande un build installable à tester, en particulier si le SDK Android/Flutter n'est pas installé localement."
argument-hint: "[branche] [--review full|lean|solo]"
user-invocable: true
allowed-tools: Read, Glob, Grep, Bash, Task, AskUserQuestion
model: sonnet
agent: mobile-release-engineer
---

Livre un APK installable sans supposer que l'environnement a le SDK
Android. Non-autonome sur un seul point : modifier le workflow CI demande
un accord explicite avant de pousser (voir Phase 2).

## Phases
1. **Vérifier l'existant** — `.github/workflows/build-apk.yml` existe déjà
   dans ce repo (déclencheur `workflow_dispatch`). Ne pas en recréer un.
2. **Publication en release (si pas déjà en place)** — si le workflow ne
   publie pas encore l'APK en asset de release GitHub (tag `apk-latest`),
   proposer l'ajout, expliquer pourquoi (artifacts d'Action → stockage
   blob souvent bloqué en sortie, releases → domaine `github.com` presque
   toujours accessible), et attendre l'accord explicite de l'utilisateur
   avant de pousser ce changement de CI/CD.
3. **Déclencher** — `workflow_dispatch` sur la branche demandée, vérifier
   que le `head_sha` du run correspond au dernier commit attendu.
4. **Attendre sans bloquer** — programmer un check-in différé (~6-8 min
   pour un build Flutter release typique) plutôt qu'attendre en boucle.
5. **Récupérer et vérifier** — au run terminé avec succès, récupérer
   l'asset de la release `apk-latest`, le télécharger, vérifier son
   `sha256sum` contre le digest fourni par GitHub avant de le considérer
   fiable.
6. **Livrer** — en pièce jointe si le fichier passe la limite d'envoi
   (~30 Mio) ; sinon donner directement le lien
   `github.com/<owner>/<repo>/releases/download/<tag>/<fichier>`, qui
   fonctionne dans n'importe quel navigateur.
7. **Si le build échoue** — récupérer les logs du job en échec, expliquer
   la cause réelle plutôt que de relancer en boucle en espérant que ça
   passe.

## Sortie
APK livré (pièce jointe ou lien direct) + statut du run CI. Aucune
modification de code applicatif — cette skill construit et livre, elle ne
corrige pas de bug.
