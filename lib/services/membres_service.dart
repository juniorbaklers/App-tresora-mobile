import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membre.dart';

/// Table `membres` — registre nominatif des cotisants.
class MembresService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Membre>> streamMembres() {
    return _client
        .from('membres')
        .stream(primaryKey: ['id'])
        .order('nom_complet')
        .map((rows) => rows.map(Membre.fromMap).toList());
  }

  Future<void> creer(Membre membre) => _client.from('membres').insert(membre.toInsertMap());

  Future<void> modifier(String id, Map<String, dynamic> valeurs) =>
      _client.from('membres').update(valeurs).eq('id', id);

  Future<void> supprimer(String id) => _client.from('membres').delete().eq('id', id);
}
