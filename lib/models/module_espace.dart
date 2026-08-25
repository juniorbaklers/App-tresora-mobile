/// Reflète l'enum TypeScript `ModuleKey` de tresora-app (src/lib/types.ts) —
/// les fonctionnalités qu'un espace peut activer ou non. `rapports` est
/// toujours actif (obligatoire) ; `dimes`/`offrandes` ne sont cochés par
/// défaut que pour les espaces de type église, mais restent activables
/// manuellement pour n'importe quel type.
enum ModuleEspace {
  membres('membres', 'Membres'),
  cotisations('cotisations', 'Cotisations'),
  evenements('evenements', 'Événements'),
  recettes('recettes', 'Recettes'),
  depenses('depenses', 'Dépenses'),
  rapports('rapports', 'Rapports'),
  dimes('dimes', 'Dîmes'),
  offrandes('offrandes', 'Offrandes'),
  dons('dons', 'Dons'),
  contributions('contributions', 'Contributions inter-espaces');

  final String valeurBdd;
  final String libelle;
  const ModuleEspace(this.valeurBdd, this.libelle);

  bool get estObligatoire => this == ModuleEspace.rapports;

  /// Coché par défaut uniquement pour les espaces église — reste
  /// activable manuellement pour les autres types.
  bool get estSpecifiqueEglise =>
      this == ModuleEspace.dimes || this == ModuleEspace.offrandes;

  static ModuleEspace? fromBdd(String v) {
    for (final m in ModuleEspace.values) {
      if (m.valeurBdd == v) return m;
    }
    return null;
  }

  static List<ModuleEspace> listeDepuisBdd(List<dynamic>? valeurs) {
    if (valeurs == null) return [];
    return valeurs
        .map((v) => fromBdd(v as String))
        .whereType<ModuleEspace>()
        .toList();
  }

  /// Modules activés par défaut à la création d'un espace, selon son type.
  static List<ModuleEspace> parDefaut({required bool estEglise}) {
    return ModuleEspace.values
        .where((m) => !m.estSpecifiqueEglise || estEglise)
        .toList();
  }
}
