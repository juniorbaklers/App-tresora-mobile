import 'cotisation.dart' show ModePaiement;

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

/// Table `contributions_evenement` — une fiche par contribution individuelle
/// à une collecte. montant_collecte/participants de l'événement parent se
/// recalculent automatiquement côté base (trigger), comme pour les tranches
/// de cotisation : ne jamais les modifier directement.
class ContributionEvenement {
  final String id;
  final String evenementId;
  final String nomContributeur;
  final double montant;
  final ModePaiement modePaiement;
  final String responsable;
  final DateTime date;

  ContributionEvenement({
    required this.id,
    required this.evenementId,
    required this.nomContributeur,
    required this.montant,
    required this.modePaiement,
    required this.responsable,
    required this.date,
  });

  factory ContributionEvenement.fromMap(Map<String, dynamic> map) => ContributionEvenement(
        id: map['id'] as String,
        evenementId: map['evenement_id'] as String,
        nomContributeur: map['nom_contributeur'] as String,
        montant: (map['montant'] as num).toDouble(),
        modePaiement: ModePaiement.fromBdd(map['mode_paiement'] as String?),
        responsable: map['responsable'] as String? ?? '',
        date: DateTime.parse(map['date'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'evenement_id': evenementId,
        'nom_contributeur': nomContributeur,
        'montant': montant,
        'mode_paiement': modePaiement.valeurBdd,
        'responsable': responsable,
      };
}
