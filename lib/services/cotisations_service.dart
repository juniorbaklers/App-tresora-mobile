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

  /// Ajoute des membres à une cotisation déjà créée (ligne
  /// `paiements_cotisation` à zéro, statut impayé) — pour un membre arrivé
  /// après coup, sans avoir à recréer la cotisation. Reprend
  /// `AjouterMembresDialog` de tresora-app.
  Future<void> ajouterMembres(
      String cotisationId, double montant, List<String> membreIds) async {
    if (membreIds.isEmpty) return;
    await _client.from('paiements_cotisation').insert([
      for (final membreId in membreIds)
        {
          'cotisation_id': cotisationId,
          'membre_id': membreId,
          'montant_du': montant,
        },
    ]);
  }
}

/// Table `paiements_cotisation` — statut de paiement d'un membre pour une
/// cotisation donnée.
class PaiementsCotisationService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<PaiementCotisation>> streamPaiements(String cotisationId) {
    final flux = _client
        .from('paiements_cotisation')
        .stream(primaryKey: ['id'])
        .eq('cotisation_id', cotisationId);
    return avecCacheHorsLigne('paiements_cotisation_$cotisationId', flux)
        .map((rows) => rows.map(PaiementCotisation.fromMap).toList());
  }

  /// Récupère en une seule requête les paiements de plusieurs cotisations
  /// (au lieu d'ouvrir un flux temps réel par cotisation) — utilisé par les
  /// écrans qui agrègent sur toutes les cotisations d'un espace (Paiement,
  /// tableau de bord groupe, fiche membre) pour éviter d'accumuler des
  /// dizaines de connexions temps réel simultanées. [cacheKey] doit
  /// identifier l'espace (stable d'un appel à l'autre) pour que le repli
  /// hors-ligne retrouve le bon instantané.
  Future<List<PaiementCotisation>> fetchPourCotisations(
      List<String> cotisationIds,
      {required String cacheKey}) async {
    if (cotisationIds.isEmpty) return [];
    final rows = await avecCacheHorsLigneFuture(
      'paiements_espace_$cacheKey',
      () => _client
          .from('paiements_cotisation')
          .select()
          .inFilter('cotisation_id', cotisationIds),
    );
    return rows.map(PaiementCotisation.fromMap).toList();
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

  /// Récupère en une seule requête les tranches de plusieurs paiements
  /// (au lieu d'ouvrir un flux temps réel par paiement) — même logique que
  /// [PaiementsCotisationService.fetchPourCotisations]. [cacheKey] doit
  /// identifier le contexte d'appel (ex. la cotisation) pour que le repli
  /// hors-ligne retrouve le bon instantané.
  Future<List<Tranche>> fetchPourPaiements(List<String> paiementIds,
      {required String cacheKey}) async {
    if (paiementIds.isEmpty) return [];
    final rows = await avecCacheHorsLigneFuture(
      'tranches_$cacheKey',
      () => _client
          .from('tranches')
          .select()
          .inFilter('paiement_cotisation_id', paiementIds)
          .order('date', ascending: false),
    );
    return rows.map(Tranche.fromMap).toList();
  }
}
