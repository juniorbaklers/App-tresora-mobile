/// Table `caisses`.
class Caisse {
  final String id;
  final String nom;
  final bool incluseCaisseGenerale;
  final bool actif;
  final int ordre;

  Caisse({
    required this.id,
    required this.nom,
    required this.incluseCaisseGenerale,
    required this.actif,
    required this.ordre,
  });

  factory Caisse.fromMap(Map<String, dynamic> map) => Caisse(
        id: map['id'] as String,
        nom: map['nom'] as String,
        incluseCaisseGenerale: map['incluse_caisse_generale'] as bool? ?? true,
        actif: map['actif'] as bool? ?? true,
        ordre: (map['ordre'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toInsertMap() => {
        'nom': nom,
        'incluse_caisse_generale': incluseCaisseGenerale,
        'actif': actif,
        'ordre': ordre,
      };
}
