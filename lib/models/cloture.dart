/// Table `clotures` — clôture du dimanche (ou de tout culte) : ce qui a été
/// compté en caisse, comparé à ce que les écritures de trésorerie
/// enregistrent séparément. Spécifique église mais table générique.
class Cloture {
  final String id;
  final String espaceId;
  final DateTime date;
  final String culte;
  final double offrandeOrdinaire;
  final double offrandeSpeciale;
  final double dimes;
  final double autresRecettes;
  final double totalCompte;
  final String responsable;
  final String? justification;

  Cloture({
    required this.id,
    required this.espaceId,
    required this.date,
    required this.culte,
    required this.offrandeOrdinaire,
    required this.offrandeSpeciale,
    required this.dimes,
    required this.autresRecettes,
    required this.totalCompte,
    required this.responsable,
    this.justification,
  });

  double get totalDeclare =>
      offrandeOrdinaire + offrandeSpeciale + dimes + autresRecettes;

  double get ecart => totalCompte - totalDeclare;

  factory Cloture.fromMap(Map<String, dynamic> map) => Cloture(
        id: map['id'] as String,
        espaceId: map['espace_id'] as String,
        date: DateTime.parse(map['date'] as String),
        culte: map['culte'] as String? ?? '',
        offrandeOrdinaire: (map['offrande_ordinaire'] as num?)?.toDouble() ?? 0,
        offrandeSpeciale: (map['offrande_speciale'] as num?)?.toDouble() ?? 0,
        dimes: (map['dimes'] as num?)?.toDouble() ?? 0,
        autresRecettes: (map['autres_recettes'] as num?)?.toDouble() ?? 0,
        totalCompte: (map['total_compte'] as num?)?.toDouble() ?? 0,
        responsable: map['responsable'] as String? ?? '',
        justification: map['justification'] as String?,
      );

  Map<String, dynamic> toInsertMap() => {
        'espace_id': espaceId,
        'date': date.toIso8601String().substring(0, 10),
        'culte': culte,
        'offrande_ordinaire': offrandeOrdinaire,
        'offrande_speciale': offrandeSpeciale,
        'dimes': dimes,
        'autres_recettes': autresRecettes,
        'total_compte': totalCompte,
        'responsable': responsable,
        'justification': justification,
      };
}
