enum StatutEvenement {
  planifie('planifie', 'Planifié'),
  actif('actif', 'En cours'),
  termine('termine', 'Terminé');

  final String valeurBdd;
  final String libelle;
  const StatutEvenement(this.valeurBdd, this.libelle);

  static StatutEvenement fromBdd(String v) =>
      StatutEvenement.values.firstWhere((s) => s.valeurBdd == v, orElse: () => StatutEvenement.planifie);
}

/// Table `evenements` — collecte ponctuelle (fête, projet, urgence...) avec
/// objectif optionnel et suivi du montant collecté / du nombre de
/// participants.
class Evenement {
  final String id;
  final String espaceId;
  final String nom;
  final String description;
  final DateTime dateDebut;
  final DateTime dateFin;
  final double? montantCible;
  final double? montantSuggere;
  final double montantCollecte;
  final int participants;
  final StatutEvenement statut;

  Evenement({
    required this.id,
    required this.espaceId,
    required this.nom,
    required this.description,
    required this.dateDebut,
    required this.dateFin,
    this.montantCible,
    this.montantSuggere,
    required this.montantCollecte,
    required this.participants,
    required this.statut,
  });

  double? get progression => (montantCible == null || montantCible == 0) ? null : montantCollecte / montantCible!;

  factory Evenement.fromMap(Map<String, dynamic> map) => Evenement(
        id: map['id'] as String,
        espaceId: map['espace_id'] as String,
        nom: map['nom'] as String,
        description: map['description'] as String? ?? '',
        dateDebut: DateTime.parse(map['date_debut'] as String),
        dateFin: DateTime.parse(map['date_fin'] as String),
        montantCible: (map['montant_cible'] as num?)?.toDouble(),
        montantSuggere: (map['montant_suggere'] as num?)?.toDouble(),
        montantCollecte: (map['montant_collecte'] as num?)?.toDouble() ?? 0,
        participants: (map['participants'] as num?)?.toInt() ?? 0,
        statut: StatutEvenement.fromBdd(map['statut'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'espace_id': espaceId,
        'nom': nom,
        'description': description,
        'date_debut': dateDebut.toIso8601String().substring(0, 10),
        'date_fin': dateFin.toIso8601String().substring(0, 10),
        'montant_cible': montantCible,
        'montant_suggere': montantSuggere,
        'statut': statut.valeurBdd,
      };
}
