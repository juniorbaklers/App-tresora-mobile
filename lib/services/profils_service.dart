import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profil.dart';

/// Table `profils` — un profil par utilisateur (identité globale).
class ProfilsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<Profil?> streamMonProfil(String userId) {
    return _client
        .from('profils')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : Profil.fromMap(rows.first));
  }
}
