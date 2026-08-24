import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/caisse.dart';

/// Table `caisses`. Lecture ouverte à tout utilisateur authentifié ;
/// écriture réservée au Trésorier Principal (RLS `ecriture_caisses_principal`).
class CaissesService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Caisse>> streamCaisses() {
    return _client
        .from('caisses')
        .stream(primaryKey: ['id'])
        .order('ordre')
        .map((rows) => rows.map(Caisse.fromMap).toList());
  }

  Future<void> creer(Caisse caisse) => _client.from('caisses').insert(caisse.toInsertMap());

  Future<void> modifier(String id, Map<String, dynamic> valeurs) =>
      _client.from('caisses').update(valeurs).eq('id', id);
}
