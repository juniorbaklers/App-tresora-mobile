import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profil.dart';
import '../utils/cache_hors_ligne.dart';

/// Table `profils` — un profil par utilisateur (identité globale).
class ProfilsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<Profil?> streamMonProfil(String userId) {
    final flux = _client
        .from('profils')
        .stream(primaryKey: ['id'])
        .eq('id', userId);
    return avecCacheHorsLigne('mon_profil_$userId', flux)
        .map((rows) => rows.isEmpty ? null : Profil.fromMap(rows.first));
  }
}
