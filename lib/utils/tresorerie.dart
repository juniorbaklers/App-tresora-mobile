import '../models/caisse.dart';
import '../models/mouvement.dart';

/// Calculs de soldes — reproduit fidèlement la logique de `app.js`
/// (afficherDashboard) : la "Caisse Générale" agrège toutes les caisses
/// marquées `incluse_caisse_generale = true`, et les dépenses qui lui sont
/// imputées ont `caisse_id = null`. Les caisses séparées (ex: ECODIM) ont
/// leur propre solde indépendant.
class Tresorerie {
  static Set<String> idsCaissesGenerales(List<Caisse> caisses) =>
      caisses.where((c) => c.incluseCaisseGenerale).map((c) => c.id).toSet();

  static double totalEntreesCaisseGenerale(List<Caisse> caisses, List<Mouvement> mouvements) {
    final ids = idsCaissesGenerales(caisses);
    return mouvements
        .where((m) => m.type == TypeMouvement.entree && m.caisseId != null && ids.contains(m.caisseId))
        .fold(0.0, (a, m) => a + m.montant);
  }

  static double totalDepensesCaisseGenerale(List<Mouvement> mouvements) {
    return mouvements
        .where((m) => m.type == TypeMouvement.depense && m.caisseId == null)
        .fold(0.0, (a, m) => a + m.montant);
  }

  static double soldeCaisseGenerale(List<Caisse> caisses, List<Mouvement> mouvements) =>
      totalEntreesCaisseGenerale(caisses, mouvements) - totalDepensesCaisseGenerale(mouvements);

  /// Solde d'une caisse séparée (non incluse dans la caisse générale).
  static double soldeCaisse(String caisseId, List<Mouvement> mouvements) {
    final entrees = mouvements
        .where((m) => m.type == TypeMouvement.entree && m.caisseId == caisseId)
        .fold(0.0, (a, m) => a + m.montant);
    final depenses = mouvements
        .where((m) => m.type == TypeMouvement.depense && m.caisseId == caisseId)
        .fold(0.0, (a, m) => a + m.montant);
    return entrees - depenses;
  }

  /// Entrées/dépenses de la caisse générale, mois par mois, pour une année.
  static ({List<double> entrees, List<double> depenses}) parMoisCaisseGenerale(
    List<Caisse> caisses,
    List<Mouvement> mouvements,
    int annee,
  ) {
    final ids = idsCaissesGenerales(caisses);
    final entrees = List<double>.filled(12, 0);
    final depenses = List<double>.filled(12, 0);
    for (final m in mouvements) {
      if (m.date.year != annee) continue;
      final mois = m.date.month - 1;
      if (m.type == TypeMouvement.entree && m.caisseId != null && ids.contains(m.caisseId)) {
        entrees[mois] += m.montant;
      } else if (m.type == TypeMouvement.depense && m.caisseId == null) {
        depenses[mois] += m.montant;
      }
    }
    return (entrees: entrees, depenses: depenses);
  }
}
