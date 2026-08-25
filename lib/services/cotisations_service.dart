import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cotisation.dart';
import '../utils/cache_hors_ligne.dart';

/// Tables `cotisations` + `paiements_cotisation` + `tranches`.
class CotisationsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Cotisation>> streamCotisations(String espaceId) {
    final flux = _client
        .from('cotisations')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('date_limite');
    return avecCacheHorsLigne('cotisations_$espaceId', flux)
        .map((rows) => rows.map(Cotisation.fromMap).toList());
  }

  /// Crée la cotisation puis génère une ligne `paiements_cotisation` (à
  /// zéro, statut impayé) pour chaque membre actif de l'espace — c'est ce
  /// qui rend la cotisation "assignée" à tout le monde dès sa création.
  Future<void> creer(Cotisation cotisation,
      {required List<String> membreIdsActifs}) async {
    final row = await _client
        .from('cotisations')
        .insert(cotisation.toInsertMap())
        .select()
        .single();
    final cotisationId = row['id'] as String;
    if (membreIdsActifs.isEmpty) return;
    await _client.from('paiements_cotisation').insert([
      for (final membreId in membreIdsActifs)
        {
          'cotisation_id': cotisationId,
          'membre_id': membreId,
          'montant_du': cotisation.montant
        },
    ]);
  }
}

/// Table `paiements_cotisation` — statut de paiement d'un membre pour une
/// cotisation donnée.
class PaiementsCotisationService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<PaiementCotisation>> streamPaiements(String cotisationId) {
    return _client
        .from('paiements_cotisation')
        .stream(primaryKey: ['id'])
        .eq('cotisation_id', cotisationId)
        .map((rows) => rows.map(PaiementCotisation.fromMap).toList());
  }
}

/// Table `tranches` — un versement isolé sur un paiement de cotisation.
/// montant_paye/statut du paiement parent se recalculent automatiquement
/// côté base (trigger) dès qu'une tranche est insérée.
class TranchesService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Tranche>> streamTranches(String paiementCotisationId) {
    return _client
        .from('tranches')
        .stream(primaryKey: ['id'])
        .eq('paiement_cotisation_id', paiementCotisationId)
        .order('date', ascending: false)
        .map((rows) => rows.map(Tranche.fromMap).toList());
  }

  Future<void> creer(Tranche tranche) =>
      _client.from('tranches').insert(tranche.toInsertMap());
}
