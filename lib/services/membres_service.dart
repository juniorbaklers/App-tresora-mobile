import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membre.dart';

/// Table `membres` — registre nominatif des cotisants d'un espace.
class MembresService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Membre>> streamMembres(String espaceId) {
    return _client
        .from('membres')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('nom')
        .map((rows) => rows.map(Membre.fromMap).toList());
  }

  Future<void> creer(Membre membre) => _client.from('membres').insert(membre.toInsertMap());

  Future<void> modifier(String id, Map<String, dynamic> valeurs) =>
      _client.from('membres').update(valeurs).eq('id', id);

  Future<void> supprimer(String id) => _client.from('membres').delete().eq('id', id);
}
