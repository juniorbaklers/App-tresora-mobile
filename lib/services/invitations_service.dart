import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invitation.dart';

/// Table `invitations` + RPC `accepter_invitation`.
class InvitationsService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Invitations émises pour un espace donné — vue admin (gestion des
  /// membres).
  Stream<List<Invitation>> streamInvitationsEspace(String espaceId) {
    return _client
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('espace_id', espaceId)
        .order('date', ascending: false)
        .map((rows) => rows.map(Invitation.fromMap).toList());
  }

  /// Invitations en attente adressées à l'utilisateur connecté (par
  /// email) — vue invité, sur l'écran de sélection d'espace. `.stream()`
  /// ne supporte pas les jointures : le nom de l'espace est récupéré à
  /// part et recombiné, comme pour `EspacesService.streamMesEspaces`.
  Stream<List<Invitation>> streamMesInvitations(String email) {
    return _client
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('email', email.trim().toLowerCase())
        .eq('acceptee', false)
        .order('date', ascending: false)
        .asyncMap((rows) async {
          if (rows.isEmpty) return <Invitation>[];
          final espaceIds =
              rows.map((r) => r['espace_id'] as String).toSet().toList();
          final espaces = await _client
              .from('espaces')
              .select('id, nom')
              .inFilter('id', espaceIds);
          final nomsParId = {
            for (final e in espaces) e['id'] as String: e['nom'] as String
          };
          return rows.map((r) {
            final invitation = Invitation.fromMap(r);
            final nom = nomsParId[invitation.espaceId];
            return nom == null
                ? invitation
                : Invitation(
                    id: invitation.id,
                    espaceId: invitation.espaceId,
                    email: invitation.email,
                    role: invitation.role,
                    inviteParId: invitation.inviteParId,
                    date: invitation.date,
                    acceptee: invitation.acceptee,
                    nomEspace: nom,
                  );
          }).toList();
        });
  }

  Future<void> inviter(Invitation invitation) =>
      _client.from('invitations').insert(invitation.toInsertMap());

  /// Annule (admin) ou refuse (invité) une invitation — même opération,
  /// c'est la RLS qui distingue qui a le droit de le faire.
  Future<void> supprimer(String invitationId) =>
      _client.from('invitations').delete().eq('id', invitationId);

  /// Accepte l'invitation : crée la ligne `espace_membres` et marque
  /// l'invitation acceptée, en une transaction côté base (RPC security
  /// definer). Retourne l'id de l'espace rejoint.
  Future<String> accepter(String invitationId) async {
    final espaceId = await _client
        .rpc('accepter_invitation', params: {'p_invitation_id': invitationId});
    return espaceId as String;
  }
}
