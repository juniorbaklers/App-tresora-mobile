import 'role.dart';

enum EspaceType {
  eglise('eglise', 'Église'),
  groupe('groupe', 'Groupe'),
  association('association', 'Association'),
  autre('autre', 'Autre');

  final String valeurBdd;
  final String libelle;
  const EspaceType(this.valeurBdd, this.libelle);

  static EspaceType fromBdd(String v) =>
      EspaceType.values.firstWhere((t) => t.valeurBdd == v, orElse: () => EspaceType.autre);
}

/// Table `espaces` — le concept central : chaque organisation (église,
/// groupe, association, ou perso) est une trésorerie indépendante.
class Espace {
  final String id;
  final String nom;
  final EspaceType type;
  final String initiales;
  final String devise;
  final double soldeInitial;

  Espace({
    required this.id,
    required this.nom,
    required this.type,
    required this.initiales,
    required this.devise,
    required this.soldeInitial,
  });

  factory Espace.fromMap(Map<String, dynamic> map) => Espace(
        id: map['id'] as String,
        nom: map['nom'] as String,
        type: EspaceType.fromBdd(map['type'] as String),
        initiales: map['initiales'] as String? ?? '',
        devise: map['devise'] as String? ?? 'XOF',
        soldeInitial: (map['solde_initial'] as num?)?.toDouble() ?? 0,
      );
}

/// Ligne de la table `espace_membres` : le rôle d'un utilisateur dans un
/// espace donné. Combinée à Espace pour afficher "mes espaces".
class EspaceAvecRole {
  final Espace espace;
  final RoleEspace role;

  EspaceAvecRole({required this.espace, required this.role});
}
