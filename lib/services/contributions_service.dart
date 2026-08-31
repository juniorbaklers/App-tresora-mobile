import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contribution.dart';
import '../utils/cache_hors_ligne.dart';

/// Tables `contributions` + `contribution_versements`. `.stream()` ne
/// supportant pas les filtres OR, les demandes envoyées et reçues sont
/// deux flux distincts plutôt qu'un seul filtré côté client.
class ContributionsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Contribution>> streamEnvoyees(String espaceId) {
    final flux = _client
        .from('contributions')
        .stream(primaryKey: ['id'])
        .eq('espace_demandeur_id', espaceId)
        .order('date_limite');
    return avecCacheHorsLigne('contributions_envoyees_$espaceId', flux)
        .asyncMap(_avecNomsEspaceCible);
  }

  Stream<List<Contribution>> streamRecues(String espaceId) {
    final flux = _client
        .from('contributions')
        .stream(primaryKey: ['id'])
        .eq('espace_cible_id', espaceId)
        .order('date_limite');
    return avecCacheHorsLigne('contributions_recues_$espaceId', flux)
        .asyncMap(_avecNomsEspaceDemandeur);
  }

  Future<List<Contribution>> _avecNomsEspaceCible(
          List<Map<String, dynamic>> rows) =>
      _avecNoms(rows, colonneAResoudre: 'espace_cible_id', cible: true);

  Future<List<Contribution>> _avecNomsEspaceDemandeur(
          List<Map<String, dynamic>> rows) =>
      _avecNoms(rows, colonneAResoudre: 'espace_demandeur_id', cible: false);

  Future<List<Contribution>> _avecNoms(
    List<Map<String, dynamic>> rows, {
    required String colonneAResoudre,
    required bool cible,
  }) async {
    if (rows.isEmpty) return <Contribution>[];
    final ids = rows.map((r) => r[colonneAResoudre] as String).toSet().toList();
    final espaces = await avecCacheHorsLigneFuture(
      'contributions_noms_espaces_$colonneAResoudre',
      () => _client.from('espaces').select('id, nom').inFilter('id', ids),
    );
    final nomsParId = {
      for (final e in espaces) e['id'] as String: e['nom'] as String
    };
    return rows.map((r) {
      final contribution = Contribution.fromMap(r);
      final nom = nomsParId[r[colonneAResoudre] as String];
      return cible
          ? contribution.avecNoms(cible: nom)
          : contribution.avecNoms(demandeur: nom);
    }).toList();
  }

  Future<void> creer(Contribution contribution) =>
      _client.from('contributions').insert(contribution.toInsertMap());

  Stream<List<ContributionVersement>> streamVersements(String contributionId) {
    final flux = _client
        .from('contribution_versements')
        .stream(primaryKey: ['id'])
        .eq('contribution_id', contributionId)
        .order('date', ascending: false);
    return avecCacheHorsLigne('contribution_versements_$contributionId', flux)
        .map((rows) => rows.map(ContributionVersement.fromMap).toList());
  }

  /// Seul l'espace cible peut enregistrer qu'il a versé (RLS).
  Future<void> enregistrerVersement(String contributionId, double montant) =>
      _client.from('contribution_versements').insert(ContributionVersement(
              id: '',
              contributionId: contributionId,
              date: DateTime.now(),
              montant: montant)
          .toInsertMap());
}
