## Applies to
`lib/**` (app mobile Flutter — `app-tresora-mobile`)

## Standards
- MUST utiliser les tokens du thème (`AppColors`/`AppFonts` dans
  `lib/theme/app_theme.dart`) pour toute couleur/police — jamais de valeur
  hex ou de `fontFamily` en dur dans un widget d'écran. Une refonte
  d'identité visuelle se fait en changeant les VALEURS des tokens
  existants, pas en réécrivant chaque écran : si un écran a une couleur en
  dur, c'est cet écran qu'il faut corriger avant la refonte, pas après.
- MUST décider explicitement, pour toute nouvelle requête réseau qui
  alimente un écran, si elle passe par le cache hors-ligne
  (`avecCacheHorsLigne` pour un `Stream`, `avecCacheHorsLigneFuture` pour
  un `Future`, dans `lib/utils/cache_hors_ligne.dart`) ou non. Le défaut
  silencieux (pas de cache) casse l'écran à la moindre coupure réseau —
  constaté sur plusieurs écrans qui agrègent des paiements de cotisation
  avant que ça ne soit corrigé.
- MUST NOT ouvrir un flux temps réel (`.stream()`) par entité dans une
  boucle/liste — préférer une requête groupée en une seule fois
  (pattern `fetchPourXxx(List<String> ids)`) quand un écran agrège sur
  plusieurs entités (ex. tous les paiements de toutes les cotisations d'un
  espace). Des dizaines de connexions Realtime simultanées ont déjà
  dégradé la fluidité perçue sur ce projet avant d'être corrigées.
- MUST NOT committer de clé `service_role` Supabase dans
  `lib/config/supabase_config.dart` ou ailleurs — seule la clé publique
  `anon` a sa place côté client mobile.
- SHOULD garder la logique de calcul (agrégations, formatage de montants,
  providers Riverpod) strictement séparée de la présentation — un widget
  d'écran ne doit pas recalculer un total déjà exposé par un provider.
- SHOULD factoriser les widgets partagés entre les variantes d'un même
  écran (ex. dashboard église vs groupe) plutôt que dupliquer, et
  appliquer le même habillage visuel aux deux, même si une seule variante
  a été explicitement redemandée.
- SHOULD, quand l'environnement n'a pas le SDK Flutter installé (fréquent
  dans une session Claude Code distante), le dire explicitement plutôt que
  prétendre avoir vérifié la compilation. Faire une vérification manuelle
  rigoureuse à la place (équilibrage accolades/parenthèses, existence de
  chaque symbole référencé, chemins d'import) et recommander
  `flutter analyze` avant de merger.
