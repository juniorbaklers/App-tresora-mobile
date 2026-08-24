/// Table `mouvements` — recettes ("entree") et dépenses ("depense") unifiées.
enum TypeMouvement {
  entree('entree'),
  depense('depense');

  final String valeurBdd;
  const TypeMouvement(this.valeurBdd);

  static TypeMouvement fromBdd(String v) =>
      TypeMouvement.values.firstWhere((t) => t.valeurBdd == v, orElse: () => TypeMouvement.entree);
}

class Mouvement {
  final String id;
  final TypeMouvement type;
  final String? caisseId;
  final String? membreId;
  final String? nomLibre;
  final DateTime date;
  final double montant;
  final String? motif;
  final String? numeroRecu;
  final String? userId;

  Mouvement({
    required this.id,
    required this.type,
    this.caisseId,
    this.membreId,
    this.nomLibre,
    required this.date,
    required this.montant,
    this.motif,
    this.numeroRecu,
    this.userId,
  });

  factory Mouvement.fromMap(Map<String, dynamic> map) => Mouvement(
        id: map['id'] as String,
        type: TypeMouvement.fromBdd(map['type'] as String),
        caisseId: map['caisse_id'] as String?,
        membreId: map['membre_id'] as String?,
        nomLibre: map['nom_libre'] as String?,
        date: DateTime.parse(map['date'] as String),
        montant: (map['montant'] as num).toDouble(),
        motif: map['motif'] as String?,
        numeroRecu: map['numero_recu'] as String?,
        userId: map['user_id'] as String?,
      );

  Map<String, dynamic> toInsertMap() => {
        'type': type.valeurBdd,
        'caisse_id': caisseId,
        'membre_id': membreId,
        'nom_libre': nomLibre,
        'date': date.toIso8601String().substring(0, 10),
        'montant': montant,
        'motif': motif,
      };
}
