/// Reflète l'enum Postgres `role_utilisateur` (schema.sql + schema_5_enum.sql).
enum RoleUtilisateur {
  tresorierPrincipal('tresorier_principal', 'Trésorier Principal'),
  tresorierAdjoint('tresorier_adjoint', 'Trésorier Adjoint'),
  responsableSection('responsable_section', 'Responsable de section'),
  lectureSeule('lecture_seule', 'Lecture seule');

  final String valeurBdd;
  final String libelle;
  const RoleUtilisateur(this.valeurBdd, this.libelle);

  static RoleUtilisateur fromBdd(String? v) => RoleUtilisateur.values.firstWhere(
        (r) => r.valeurBdd == v,
        orElse: () => RoleUtilisateur.lectureSeule,
      );

  bool get peutSaisir => this != RoleUtilisateur.lectureSeule;
  bool get peutSupprimer => this == RoleUtilisateur.tresorierPrincipal;
  bool get peutGererCaisses => this == RoleUtilisateur.tresorierPrincipal;
}
