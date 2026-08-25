import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tresorerie.dart';
import '../utils/cache_hors_ligne.dart';

/// Table `recettes`.
class RecettesService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Recette>> streamRecettes(String espaceId) {
    final flux = _client
        .from('recettes')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('date', ascending: false);
    return avecCacheHorsLigne('recettes_$espaceId', flux)
        .map((rows) => rows.map(Recette.fromMap).toList());
  }

  Future<void> creer(Recette recette) =>
      _client.from('recettes').insert(recette.toInsertMap());
}

/// Table `depenses`.
class DepensesService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Depense>> streamDepenses(String espaceId) {
    final flux = _client
        .from('depenses')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('date', ascending: false);
    return avecCacheHorsLigne('depenses_$espaceId', flux)
        .map((rows) => rows.map(Depense.fromMap).toList());
  }

  Future<void> creer(Depense depense) =>
      _client.from('depenses').insert(depense.toInsertMap());
}
