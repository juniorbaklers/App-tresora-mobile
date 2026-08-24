/// Reflète l'enum Postgres `role_espace` (supabase/schema_1_types_tables.sql).
/// Un rôle est toujours relatif à un espace précis — un utilisateur peut être
/// `proprietaire` d'un espace et simple `membre` d'un autre.
enum RoleEspace {
  proprietaire('proprietaire', 'Propriétaire'),
  administrateur('administrateur', 'Administrateur'),
  tresorier('tresorier', 'Trésorier'),
  responsable('responsable', 'Responsable'),
  membre('membre', 'Membre');

  final String valeurBdd;
  final String libelle;
  const RoleEspace(this.valeurBdd, this.libelle);

  static RoleEspace fromBdd(String? v) => RoleEspace.values.firstWhere(
        (r) => r.valeurBdd == v,
        orElse: () => RoleEspace.membre,
      );

  /// Recettes, dépenses, cotisations, membres, événements.
  bool get peutGerer => this == proprietaire || this == administrateur || this == tresorier;

  /// Réglages de l'espace, rôles des autres membres.
  bool get peutAdministrer => this == proprietaire || this == administrateur;

  /// Membres, cotisations, événements — pas l'argent.
  bool get peutGererMembres => peutGerer || this == responsable;

  bool get estProprietaire => this == proprietaire;
}
