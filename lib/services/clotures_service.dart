import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cloture.dart';
import '../utils/cache_hors_ligne.dart';

/// Table `clotures`.
class CloturesService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Cloture>> streamClotures(String espaceId) {
    final flux = _client
        .from('clotures')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('date', ascending: false);
    return avecCacheHorsLigne('clotures_$espaceId', flux)
        .map((rows) => rows.map(Cloture.fromMap).toList());
  }

  Future<void> creer(Cloture cloture) =>
      _client.from('clotures').insert(cloture.toInsertMap());
}
