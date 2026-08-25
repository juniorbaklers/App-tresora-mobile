/// Table `entrees_journal` — trace des actions significatives sur un
/// espace, alimentée uniquement par des triggers côté base (recettes,
/// dépenses, membres — voir schema_2_triggers.sql). Lecture seule côté app.
class EntreeJournal {
  final String id;
  final String espaceId;
  final DateTime date;
  final String heure;
  final String utilisateur;
  final String role;
  final String action;
  final String? ancienneValeur;
  final String? nouvelleValeur;

  EntreeJournal({
    required this.id,
    required this.espaceId,
    required this.date,
    required this.heure,
    required this.utilisateur,
    required this.role,
    required this.action,
    this.ancienneValeur,
    this.nouvelleValeur,
  });

  static String _heureCourte(String? heure) => (heure == null || heure.length < 5) ? (heure ?? '') : heure.substring(0, 5);

  factory EntreeJournal.fromMap(Map<String, dynamic> map) => EntreeJournal(
        id: map['id'] as String,
        espaceId: map['espace_id'] as String,
        date: DateTime.parse(map['date'] as String),
        heure: _heureCourte(map['heure'] as String?),
        utilisateur: map['utilisateur'] as String? ?? '',
        role: map['role'] as String? ?? '',
        action: map['action'] as String,
        ancienneValeur: map['ancienne_valeur'] as String?,
        nouvelleValeur: map['nouvelle_valeur'] as String?,
      );
}
