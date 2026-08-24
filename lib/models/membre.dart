/// Table `membres` — registre nominatif des cotisants d'un espace.
class Membre {
  final String id;
  final String espaceId;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final String? fonction;
  final bool actif;

  Membre({
    required this.id,
    required this.espaceId,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    this.fonction,
    required this.actif,
  });

  String get nomComplet => '$prenom $nom'.trim();

  factory Membre.fromMap(Map<String, dynamic> map) => Membre(
        id: map['id'] as String,
        espaceId: map['espace_id'] as String,
        nom: map['nom'] as String,
        prenom: map['prenom'] as String,
        telephone: map['telephone'] as String? ?? '',
        email: map['email'] as String?,
        fonction: map['fonction'] as String?,
        actif: (map['statut'] as String?) == 'actif',
      );

  Map<String, dynamic> toInsertMap() => {
        'espace_id': espaceId,
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'email': email,
        'fonction': fonction,
        'statut': actif ? 'actif' : 'inactif',
      };
}
