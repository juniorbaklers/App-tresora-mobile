enum TypeNotification {
  cotisationRetard('cotisation_retard', 'Cotisation en retard'),
  nouveauPaiement('nouveau_paiement', 'Nouveau paiement'),
  contributionDemandee('contribution_demandee', 'Contribution demandée'),
  contributionRecue('contribution_recue', 'Contribution reçue'),
  evenementBientot('evenement_bientot', 'Événement bientôt'),
  rapportDisponible('rapport_disponible', 'Rapport disponible');

  final String valeurBdd;
  final String libelle;
  const TypeNotification(this.valeurBdd, this.libelle);

  static TypeNotification fromBdd(String v) =>
      TypeNotification.values.firstWhere((t) => t.valeurBdd == v, orElse: () => TypeNotification.rapportDisponible);
}

/// Table `notifications` — boîte personnelle de l'utilisateur, alimentée
/// uniquement par des triggers côté base (voir schema_2_triggers.sql).
/// L'app ne fait que lire et marquer comme lu.
class NotificationTresora {
  final String id;
  final String espaceId;
  final TypeNotification type;
  final String titre;
  final String description;
  final DateTime date;
  final bool lue;

  NotificationTresora({
    required this.id,
    required this.espaceId,
    required this.type,
    required this.titre,
    required this.description,
    required this.date,
    required this.lue,
  });

  factory NotificationTresora.fromMap(Map<String, dynamic> map) => NotificationTresora(
        id: map['id'] as String,
        espaceId: map['espace_id'] as String,
        type: TypeNotification.fromBdd(map['type'] as String),
        titre: map['titre'] as String,
        description: map['description'] as String? ?? '',
        date: DateTime.parse(map['date'] as String),
        lue: map['lue'] as bool? ?? false,
      );
}
