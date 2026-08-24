import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mouvement.dart';

/// Table `mouvements` — recettes/dépenses. La numérotation des reçus est
/// générée côté base par la fonction SQL `prochain_numero_recu()`
/// (schema.sql), verrouillée par `schema_3_securite.sql`.
class MouvementsService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Mouvement>> streamMouvements() {
    return _client
        .from('mouvements')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false)
        .map((rows) => rows.map(Mouvement.fromMap).toList());
  }

  /// Crée un mouvement. Pour une entrée (recette), génère et attache un
  /// numéro de reçu séquentiel via la fonction SQL dédiée.
  Future<void> creer(Mouvement mouvement) async {
    var donnees = mouvement.toInsertMap();
    if (mouvement.type == TypeMouvement.entree) {
      final numero = await _client.rpc('prochain_numero_recu') as String;
      donnees = {...donnees, 'numero_recu': numero};
    }
    await _client.from('mouvements').insert(donnees);
  }

  Future<void> modifier(String id, Map<String, dynamic> valeurs) =>
      _client.from('mouvements').update(valeurs).eq('id', id);

  Future<void> supprimer(String id) => _client.from('mouvements').delete().eq('id', id);
}
