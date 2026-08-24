/// Table `profils` — identité globale d'un utilisateur, indépendante des
/// espaces (le rôle, lui, dépend de l'espace : voir EspaceMembre).
class Profil {
  final String id;
  final String nomComplet;
  final String email;

  Profil({required this.id, required this.nomComplet, required this.email});

  factory Profil.fromMap(Map<String, dynamic> map) => Profil(
        id: map['id'] as String,
        nomComplet: map['nom_complet'] as String? ?? '',
        email: map['email'] as String? ?? '',
      );
}
