import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profil.dart';

/// Table `profils` — un profil par utilisateur (rôle, nom complet).
class ProfilsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Flux temps réel du profil de l'utilisateur connecté.
  Stream<Profil?> streamMonProfil(String userId) {
    return _client
        .from('profils')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : Profil.fromMap(rows.first));
  }

  Stream<List<Profil>> streamTousLesProfils() {
    return _client.from('profils').stream(primaryKey: ['id']).map(
          (rows) => rows.map(Profil.fromMap).toList(),
        );
  }
}
