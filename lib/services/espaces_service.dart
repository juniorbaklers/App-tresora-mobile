import 'dart:math';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/espace.dart';
import '../models/membre_compte.dart';
import '../models/module_espace.dart';
import '../models/profil.dart';
import '../models/role.dart';
import '../utils/cache_hors_ligne.dart';

/// UUID v4 généré côté client (aucun paquet supplémentaire) — nécessaire
/// pour `EspacesService.creer()`, voir le commentaire sur cette méthode.
String _genererUuidV4() {
  final octets = Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)));
  octets[6] = (octets[6] & 0x0f) | 0x40;
  octets[8] = (octets[8] & 0x3f) | 0x80;
  final hex = octets.map((o) => o.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}

/// Tables `espaces` + `espace_membres` — le concept central : chaque
/// organisation est une trésorerie indépendante, et un utilisateur peut en
/// gérer plusieurs avec des rôles différents.
class EspacesService {
  final SupabaseClient _client = Supabase.instance.client;

  /// "Mes espaces" en temps réel : écoute mes lignes espace_membres, puis
  /// recharge les espaces correspondants à chaque changement (ajout/retrait
  /// d'un espace, changement de rôle). C'est le tout premier écran après
  /// connexion, donc le flux combiné (espace + rôle) est lui-même mis en
  /// cache hors-ligne, sous forme de lignes brutes (champs de `espaces`
  /// plus `role`) pour rester compatible avec `avecCacheHorsLigne`.
  Stream<List<EspaceAvecRole>> streamMesEspaces(String userId) {
    final flux = _client
        .from('espace_membres')
        .stream(primaryKey: ['espace_id', 'user_id'])
        .eq('user_id', userId)
        .asyncMap((lignes) async {
          if (lignes.isEmpty) return <Map<String, dynamic>>[];
          final ids = lignes.map((l) => l['espace_id'] as String).toList();
          final espacesData =
              await _client.from('espaces').select().inFilter('id', ids);
          final espacesParId = {
            for (final e in espacesData) e['id'] as String: e
          };
          return lignes
              .where((l) => espacesParId.containsKey(l['espace_id']))
              .map((l) => {...espacesParId[l['espace_id']]!, 'role': l['role']})
              .toList();
        });
    return avecCacheHorsLigne('mes_espaces_$userId', flux).map(
      (rows) => rows
          .map((r) => EspaceAvecRole(
              espace: Espace.fromMap(r),
              role: RoleEspace.fromBdd(r['role'] as String)))
          .toList(),
    );
  }

  /// Crée un espace ; le créateur en devient automatiquement propriétaire
  /// (trigger SQL `gerer_nouvel_espace`, ajout dans `espace_membres`).
  ///
  /// L'id est généré côté client puis l'insert et la lecture sont deux
  /// appels séparés (pas de `.select()` chaîné sur l'insert) : la policy
  /// RLS `espaces_lecture` n'autorise que les membres de l'espace, et le
  /// trigger qui fait du créateur un membre n'est pas encore visible à la
  /// clause RETURNING d'un insert — seulement à une requête ultérieure
  /// distincte (vérifié empiriquement sur ce projet).
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
    final modules =
        ModuleEspace.parDefaut(estEglise: type == EspaceType.eglise);
    final id = _genererUuidV4();
    await _client.from('espaces').insert({
      'id': id,
      'nom': nom,
      'type': type.valeurBdd,
      'initiales': initiales.isEmpty ? '?' : initiales,
      'devise': devise,
      'created_by': createdBy,
      'modules': modules.map((m) => m.valeurBdd).toList(),
    });
    final row = await _client.from('espaces').select().eq('id', id).single();
    return Espace.fromMap(row);
  }

  /// Modifie les réglages de l'espace (nom/devise/solde initial/modules) —
  /// réservé aux propriétaires/administrateurs (RLS `espaces_maj`).
  Future<void> modifier(String espaceId, Map<String, dynamic> champs) =>
      _client.from('espaces').update(champs).eq('id', espaceId);

  Future<void> definirModules(String espaceId, List<ModuleEspace> modules) =>
      modifier(espaceId, {'modules': modules.map((m) => m.valeurBdd).toList()});

  /// Comptes utilisateurs de l'espace avec leur rôle — pour la gestion des
  /// rôles dans Réglages. `.stream()` ne supportant pas les jointures, le
  /// profil de chaque membre est récupéré à part.
  Stream<List<MembreCompte>> streamMembresCompte(String espaceId) {
    final flux = _client
        .from('espace_membres')
        .stream(primaryKey: ['espace_id', 'user_id'])
        .eq('espace_id', espaceId);
    return avecCacheHorsLigne('membres_compte_$espaceId', flux)
        .asyncMap((lignes) async {
          if (lignes.isEmpty) return <MembreCompte>[];
          final userIds = lignes.map((l) => l['user_id'] as String).toList();
          final profilsData = await avecCacheHorsLigneFuture(
            'membres_compte_profils_$espaceId',
            () => _client.from('profils').select().inFilter('id', userIds),
          );
          final profilsParId = {
            for (final p in profilsData) p['id'] as String: Profil.fromMap(p)
          };
          return lignes
              .where((l) => profilsParId.containsKey(l['user_id']))
              .map((l) => MembreCompte(
                    profil: profilsParId[l['user_id']]!,
                    role: RoleEspace.fromBdd(l['role'] as String),
                  ))
              .toList();
        });
  }

  Future<void> changerRole(String espaceId, String userId, RoleEspace role) =>
      _client
          .from('espace_membres')
          .update({'role': role.valeurBdd})
          .eq('espace_id', espaceId)
          .eq('user_id', userId);

  Future<void> retirerMembre(String espaceId, String userId) => _client
      .from('espace_membres')
      .delete()
      .eq('espace_id', espaceId)
      .eq('user_id', userId);
}
