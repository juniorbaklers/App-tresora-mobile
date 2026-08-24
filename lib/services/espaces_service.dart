import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espace.dart';
import '../models/role.dart';

/// Tables `espaces` + `espace_membres` — le concept central : chaque
/// organisation est une trésorerie indépendante, et un utilisateur peut en
/// gérer plusieurs avec des rôles différents.
class EspacesService {
  final SupabaseClient _client = Supabase.instance.client;

  /// "Mes espaces" en temps réel : écoute mes lignes espace_membres, puis
  /// recharge les espaces correspondants à chaque changement (ajout/retrait
  /// d'un espace, changement de rôle).
  Stream<List<EspaceAvecRole>> streamMesEspaces(String userId) {
    return _client
        .from('espace_membres')
        .stream(primaryKey: ['espace_id', 'user_id'])
        .eq('user_id', userId)
        .asyncMap((lignes) async {
      if (lignes.isEmpty) return <EspaceAvecRole>[];
      final ids = lignes.map((l) => l['espace_id'] as String).toList();
      final espacesData = await _client.from('espaces').select().inFilter('id', ids);
      final espacesParId = {for (final e in espacesData) e['id'] as String: Espace.fromMap(e)};
      return lignes
          .where((l) => espacesParId.containsKey(l['espace_id']))
          .map((l) => EspaceAvecRole(
                espace: espacesParId[l['espace_id']]!,
                role: RoleEspace.fromBdd(l['role'] as String),
              ))
          .toList();
    });
  }

  /// Crée un espace ; le créateur en devient automatiquement propriétaire
  /// (trigger SQL `gerer_nouvel_espace`).
  Future<Espace> creer({
    required String nom,
    required EspaceType type,
    required String devise,
    required String createdBy,
  }) async {
    final initiales = nom
        .trim()
        .split(RegExp(r'\s+'))
        .where((m) => m.isNotEmpty)
        .take(2)
        .map((m) => m[0].toUpperCase())
        .join();
    final row = await _client
        .from('espaces')
        .insert({
          'nom': nom,
          'type': type.valeurBdd,
          'initiales': initiales.isEmpty ? '?' : initiales,
          'devise': devise,
          'created_by': createdBy,
        })
        .select()
        .single();
    return Espace.fromMap(row);
  }
}
