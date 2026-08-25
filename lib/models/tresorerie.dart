import 'cotisation.dart' show ModePaiement;

enum CategorieRecette {
  dime('dime', 'Dîme'),
  offrandeOrdinaire('offrande_ordinaire', 'Offrande ordinaire'),
  offrandeSpeciale('offrande_speciale', 'Offrande spéciale'),
  offrandeCulteSoir('offrande_culte_soir', 'Offrande du soir'),
  cotisation('cotisation', 'Cotisation'),
  don('don', 'Don'),
  activite('activite', 'Activité'),
  autre('autre', 'Autre');

  final String valeurBdd;
  final String libelle;
  const CategorieRecette(this.valeurBdd, this.libelle);

  static CategorieRecette fromBdd(String v) =>
      CategorieRecette.values.firstWhere((c) => c.valeurBdd == v,
          orElse: () => CategorieRecette.autre);
}

/// Table `recettes`.
class Recette {
  final String id;
  final String espaceId;
  final DateTime date;
  final double montant;
  final CategorieRecette categorie;
  final String libelle;
  final String responsable;
  final String? commentaire;

  Recette({
    required this.id,
    required this.espaceId,
    required this.date,
    required this.montant,
    required this.categorie,
    required this.libelle,
    required this.responsable,
    this.commentaire,
  });

  factory Recette.fromMap(Map<String, dynamic> map) => Recette(
        id: map['id'] as String,
        espaceId: map['espace_id'] as String,
        date: DateTime.parse(map['date'] as String),
        montant: (map['montant'] as num).toDouble(),
        categorie: CategorieRecette.fromBdd(map['categorie'] as String),
        libelle: map['libelle'] as String? ?? '',
        responsable: map['responsable'] as String? ?? '',
        commentaire: map['commentaire'] as String?,
      );

  Map<String, dynamic> toInsertMap() => {
        'espace_id': espaceId,
        'date': date.toIso8601String().substring(0, 10),
        'montant': montant,
        'categorie': categorie.valeurBdd,
        'libelle': libelle,
        'responsable': responsable,
        'commentaire': commentaire,
      };
}

/// Table `depenses`.
class Depense {
  final String id;
  final String espaceId;
  final DateTime date;
  final double montant;
  final String categorie;
  final String description;
  final String beneficiaire;
  final ModePaiement modePaiement;
  final String responsable;
  final bool justificatif;

  Depense({
    required this.id,
    required this.espaceId,
    required this.date,
    required this.montant,
    required this.categorie,
    required this.description,
    required this.beneficiaire,
    this.modePaiement = ModePaiement.especes,
    required this.responsable,
    this.justificatif = false,
  });

  factory Depense.fromMap(Map<String, dynamic> map) => Depense(
        id: map['id'] as String,
        espaceId: map['espace_id'] as String,
        date: DateTime.parse(map['date'] as String),
        montant: (map['montant'] as num).toDouble(),
        categorie: map['categorie'] as String? ?? 'autre',
        description: map['description'] as String? ?? '',
        beneficiaire: map['beneficiaire'] as String? ?? '',
        modePaiement: ModePaiement.fromBdd(map['mode_paiement'] as String?),
        responsable: map['responsable'] as String? ?? '',
        justificatif: map['justificatif'] as bool? ?? false,
      );

  Map<String, dynamic> toInsertMap() => {
        'espace_id': espaceId,
        'date': date.toIso8601String().substring(0, 10),
        'montant': montant,
        'categorie': categorie,
        'description': description,
        'beneficiaire': beneficiaire,
        'mode_paiement': modePaiement.valeurBdd,
        'responsable': responsable,
        'justificatif': justificatif,
      };
}
