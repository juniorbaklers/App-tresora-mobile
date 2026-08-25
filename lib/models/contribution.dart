enum StatutContribution {
  enAttente('en_attente', 'En attente'),
  partiel('partiel', 'Partielle'),
  paye('paye', 'Réglée');

  final String valeurBdd;
  final String libelle;
  const StatutContribution(this.valeurBdd, this.libelle);

  static StatutContribution fromBdd(String v) =>
      StatutContribution.values.firstWhere((s) => s.valeurBdd == v,
          orElse: () => StatutContribution.enAttente);
}

/// Table `contributions` — seul canal financier entre deux espaces :
/// l'espace demandeur sollicite une somme auprès de l'espace cible, qui
/// enregistre ses versements (contribution_versements) sans que le
/// demandeur ne voie comment cette somme a été réunie côté cible.
class Contribution {
  final String id;
  final String projet;
  final String description;
  final String espaceDemandeurId;
  final String espaceCibleId;
  final double montantDemande;
  final double montantRecu;
  final DateTime dateLimite;
  final StatutContribution statut;
  final String? nomEspaceDemandeur;
  final String? nomEspaceCible;

  Contribution({
    required this.id,
    required this.projet,
    required this.description,
    required this.espaceDemandeurId,
    required this.espaceCibleId,
    required this.montantDemande,
    required this.montantRecu,
    required this.dateLimite,
    required this.statut,
    this.nomEspaceDemandeur,
    this.nomEspaceCible,
  });

  double get progression =>
      montantDemande == 0 ? 0 : (montantRecu / montantDemande).clamp(0, 1);

  factory Contribution.fromMap(Map<String, dynamic> map) => Contribution(
        id: map['id'] as String,
        projet: map['projet'] as String,
        description: map['description'] as String? ?? '',
        espaceDemandeurId: map['espace_demandeur_id'] as String,
        espaceCibleId: map['espace_cible_id'] as String,
        montantDemande: (map['montant_demande'] as num).toDouble(),
        montantRecu: (map['montant_recu'] as num?)?.toDouble() ?? 0,
        dateLimite: DateTime.parse(map['date_limite'] as String),
        statut: StatutContribution.fromBdd(map['statut'] as String),
      );

  Contribution avecNoms({String? demandeur, String? cible}) => Contribution(
        id: id,
        projet: projet,
        description: description,
        espaceDemandeurId: espaceDemandeurId,
        espaceCibleId: espaceCibleId,
        montantDemande: montantDemande,
        montantRecu: montantRecu,
        dateLimite: dateLimite,
        statut: statut,
        nomEspaceDemandeur: demandeur ?? nomEspaceDemandeur,
        nomEspaceCible: cible ?? nomEspaceCible,
      );

  Map<String, dynamic> toInsertMap() => {
        'projet': projet,
        'description': description,
        'espace_demandeur_id': espaceDemandeurId,
        'espace_cible_id': espaceCibleId,
        'montant_demande': montantDemande,
        'date_limite': dateLimite.toIso8601String().substring(0, 10),
      };
}

/// Table `contribution_versements` — un versement de l'espace cible vers
/// une contribution demandée. montant_recu/statut de la contribution
/// parente se recalculent automatiquement côté base (trigger).
class ContributionVersement {
  final String id;
  final String contributionId;
  final DateTime date;
  final double montant;

  ContributionVersement({
    required this.id,
    required this.contributionId,
    required this.date,
    required this.montant,
  });

  factory ContributionVersement.fromMap(Map<String, dynamic> map) =>
      ContributionVersement(
        id: map['id'] as String,
        contributionId: map['contribution_id'] as String,
        date: DateTime.parse(map['date'] as String),
        montant: (map['montant'] as num).toDouble(),
      );

  Map<String, dynamic> toInsertMap() => {
        'contribution_id': contributionId,
        'montant': montant,
      };
}
