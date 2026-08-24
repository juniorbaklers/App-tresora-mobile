enum Periodicite {
  unique('unique', 'Unique'),
  hebdomadaire('hebdomadaire', 'Hebdomadaire'),
  mensuelle('mensuelle', 'Mensuelle'),
  trimestrielle('trimestrielle', 'Trimestrielle'),
  annuelle('annuelle', 'Annuelle'),
  personnalisee('personnalisee', 'Personnalisée');

  final String valeurBdd;
  final String libelle;
  const Periodicite(this.valeurBdd, this.libelle);

  static Periodicite fromBdd(String v) =>
      Periodicite.values.firstWhere((p) => p.valeurBdd == v, orElse: () => Periodicite.unique);
}

/// Table `cotisations` — payable en une ou plusieurs tranches (voir Tranche).
class Cotisation {
  final String id;
  final String espaceId;
  final String nom;
  final String description;
  final double montant;
  final Periodicite periodicite;
  final DateTime dateLimite;
  final bool active;

  Cotisation({
    required this.id,
    required this.espaceId,
    required this.nom,
    required this.description,
    required this.montant,
    required this.periodicite,
    required this.dateLimite,
    required this.active,
  });

  factory Cotisation.fromMap(Map<String, dynamic> map) => Cotisation(
        id: map['id'] as String,
        espaceId: map['espace_id'] as String,
        nom: map['nom'] as String,
        description: map['description'] as String? ?? '',
        montant: (map['montant'] as num).toDouble(),
        periodicite: Periodicite.fromBdd(map['periodicite'] as String),
        dateLimite: DateTime.parse(map['date_limite'] as String),
        active: (map['statut'] as String?) == 'active',
      );

  Map<String, dynamic> toInsertMap() => {
        'espace_id': espaceId,
        'nom': nom,
        'description': description,
        'montant': montant,
        'periodicite': periodicite.valeurBdd,
        'date_limite': dateLimite.toIso8601String().substring(0, 10),
      };
}

enum StatutPaiement {
  paye('paye', 'Payé'),
  partiel('partiel', 'Partiel'),
  impaye('impaye', 'Impayé'),
  enRetard('en_retard', 'En retard'),
  exonere('exonere', 'Exonéré');

  final String valeurBdd;
  final String libelle;
  const StatutPaiement(this.valeurBdd, this.libelle);

  static StatutPaiement fromBdd(String v) =>
      StatutPaiement.values.firstWhere((s) => s.valeurBdd == v, orElse: () => StatutPaiement.impaye);
}

/// Table `paiements_cotisation` — une ligne par (cotisation, membre).
/// montant_paye/statut sont recalculés automatiquement côté base à chaque
/// tranche insérée/supprimée (trigger) : ne jamais les modifier directement.
class PaiementCotisation {
  final String id;
  final String cotisationId;
  final String membreId;
  final double montantDu;
  final double montantPaye;
  final StatutPaiement statut;

  PaiementCotisation({
    required this.id,
    required this.cotisationId,
    required this.membreId,
    required this.montantDu,
    required this.montantPaye,
    required this.statut,
  });

  factory PaiementCotisation.fromMap(Map<String, dynamic> map) => PaiementCotisation(
        id: map['id'] as String,
        cotisationId: map['cotisation_id'] as String,
        membreId: map['membre_id'] as String,
        montantDu: (map['montant_du'] as num).toDouble(),
        montantPaye: (map['montant_paye'] as num).toDouble(),
        statut: StatutPaiement.fromBdd(map['statut'] as String),
      );
}

enum ModePaiement {
  especes('especes', 'Espèces'),
  mobileMoney('mobile_money', 'Mobile Money'),
  virement('virement', 'Virement'),
  cheque('cheque', 'Chèque');

  final String valeurBdd;
  final String libelle;
  const ModePaiement(this.valeurBdd, this.libelle);

  static ModePaiement fromBdd(String? v) =>
      ModePaiement.values.firstWhere((m) => m.valeurBdd == v, orElse: () => ModePaiement.especes);
}

/// Table `tranches` — un versement isolé pour une cotisation d'un membre.
class Tranche {
  final String id;
  final String paiementCotisationId;
  final DateTime date;
  final double montant;
  final String responsable;
  final ModePaiement? modePaiement;

  Tranche({
    required this.id,
    required this.paiementCotisationId,
    required this.date,
    required this.montant,
    required this.responsable,
    this.modePaiement,
  });

  factory Tranche.fromMap(Map<String, dynamic> map) => Tranche(
        id: map['id'] as String,
        paiementCotisationId: map['paiement_cotisation_id'] as String,
        date: DateTime.parse(map['date'] as String),
        montant: (map['montant'] as num).toDouble(),
        responsable: map['responsable'] as String? ?? '',
        modePaiement: map['mode_paiement'] == null ? null : ModePaiement.fromBdd(map['mode_paiement'] as String),
      );

  Map<String, dynamic> toInsertMap() => {
        'paiement_cotisation_id': paiementCotisationId,
        'montant': montant,
        'responsable': responsable,
        'mode_paiement': modePaiement?.valeurBdd,
      };
}
