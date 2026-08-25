import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entree_journal.dart';
import '../utils/cache_hors_ligne.dart';

/// Table `entrees_journal` — jamais écrite par l'app, seulement lue.
class JournalService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<EntreeJournal>> streamJournal(String espaceId) {
    final flux = _client
        .from('entrees_journal')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('created_at', ascending: false);
    return avecCacheHorsLigne('journal_$espaceId', flux)
        .map((rows) => rows.map(EntreeJournal.fromMap).toList());
  }
}
