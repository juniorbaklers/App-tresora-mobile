import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/evenement.dart';
import '../utils/cache_hors_ligne.dart';

/// Table `evenements`. montant_collecte/participants sont recalculés
/// automatiquement côté base à chaque fiche insérée/supprimée dans
/// "contributions_evenement" (trigger) : ne jamais les modifier directement.
class EvenementsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Evenement>> streamEvenements(String espaceId) {
    final flux = _client
        .from('evenements')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('date_debut', ascending: false);
    return avecCacheHorsLigne('evenements_$espaceId', flux)
        .map((rows) => rows.map(Evenement.fromMap).toList());
  }

  Future<void> creer(Evenement evenement) =>
      _client.from('evenements').insert(evenement.toInsertMap());

  Future<void> changerStatut(String evenementId, StatutEvenement statut) =>
      _client
          .from('evenements')
          .update({'statut': statut.valeurBdd}).eq('id', evenementId);
}

/// Table `contributions_evenement` — une fiche par contribution individuelle.
class ContributionsEvenementService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<ContributionEvenement>> streamContributions(String evenementId) {
    final flux = _client
        .from('contributions_evenement')
        .stream(primaryKey: ['id'])
        .eq('evenement_id', evenementId)
        .order('date', ascending: false);
    return avecCacheHorsLigne('contributions_evenement_$evenementId', flux)
        .map((rows) => rows.map(ContributionEvenement.fromMap).toList());
  }

  Future<void> creer(ContributionEvenement contribution) => _client
      .from('contributions_evenement')
      .insert(contribution.toInsertMap());
}
