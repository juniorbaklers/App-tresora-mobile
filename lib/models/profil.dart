import 'role.dart';

/// Table `profils`.
class Profil {
  final String id;
  final String nomComplet;
  final RoleUtilisateur role;
  final String? sectionId;

  Profil({
    required this.id,
    required this.nomComplet,
    required this.role,
    this.sectionId,
  });

  factory Profil.fromMap(Map<String, dynamic> map) => Profil(
        id: map['id'] as String,
        nomComplet: map['nom_complet'] as String? ?? '',
        role: RoleUtilisateur.fromBdd(map['role'] as String?),
        sectionId: map['section_id'] as String?,
      );
}
