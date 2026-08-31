import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membre.dart';
import '../utils/cache_hors_ligne.dart';

/// Table `membres` — registre nominatif des cotisants d'un espace.
class MembresService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Membre>> streamMembres(String espaceId) {
    final flux = _client
        .from('membres')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('nom');
    return avecCacheHorsLigne('membres_$espaceId', flux)
        .map((rows) => rows.map(Membre.fromMap).toList());
  }

  Future<void> creer(Membre membre) =>
      _client.from('membres').insert(membre.toInsertMap());

  /// Comme [creer], mais renvoie la ligne créée — utilisé quand l'écran
  /// appelant a besoin de l'id tout de suite (ex. enregistrer un paiement
  /// de cotisation pour quelqu'un qui n'était pas encore dans le registre
  /// des membres). Contrairement à `EspacesService.creer()`, aucun
  /// contournement n'est nécessaire ici : la policy RLS `membres_lecture`
  /// (`est_membre_espace(espace_id)`) ne dépend pas d'un trigger qui
  /// s'exécuterait après cet insert, donc `.select()` chaîné voit
  /// immédiatement la ligne.
  Future<Membre> creerEtRecuperer(Membre membre) async {
    final row = await _client
        .from('membres')
        .insert(membre.toInsertMap())
        .select()
        .single();
    return Membre.fromMap(row);
  }

  Future<void> modifier(String id, Map<String, dynamic> valeurs) =>
      _client.from('membres').update(valeurs).eq('id', id);

  Future<void> supprimer(String id) =>
      _client.from('membres').delete().eq('id', id);
}
