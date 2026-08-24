/// Table `membres`.
class Membre {
  final String id;
  final String nomComplet;
  final String? telephone;
  final bool actif;

  Membre({
    required this.id,
    required this.nomComplet,
    this.telephone,
    required this.actif,
  });

  factory Membre.fromMap(Map<String, dynamic> map) => Membre(
        id: map['id'] as String,
        nomComplet: map['nom_complet'] as String,
        telephone: map['telephone'] as String?,
        actif: map['actif'] as bool? ?? true,
      );

  Map<String, dynamic> toInsertMap() => {
        'nom_complet': nomComplet,
        'telephone': telephone,
        'actif': actif,
      };
}
