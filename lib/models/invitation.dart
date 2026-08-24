import 'role.dart';

/// Table `invitations` — une invitation en attente pour rejoindre un
/// espace avec un rôle donné. Acceptée via la RPC `accepter_invitation`
/// (voir supabase/schema_3_rls.sql), pas par insertion directe dans
/// `espace_membres`.
class Invitation {
  final String id;
  final String espaceId;
  final String email;
  final RoleEspace role;
  final String inviteParId;
  final DateTime date;
  final bool acceptee;
  final String? nomEspace;

  Invitation({
    required this.id,
    required this.espaceId,
    required this.email,
    required this.role,
    required this.inviteParId,
    required this.date,
    required this.acceptee,
    this.nomEspace,
  });

  factory Invitation.fromMap(Map<String, dynamic> map) => Invitation(
        id: map['id'] as String,
        espaceId: map['espace_id'] as String,
        email: map['email'] as String,
        role: RoleEspace.fromBdd(map['role'] as String),
        inviteParId: map['invite_par'] as String,
        date: DateTime.parse(map['date'] as String),
        acceptee: map['acceptee'] as bool? ?? false,
        nomEspace: (map['espaces'] as Map<String, dynamic>?)?['nom'] as String?,
      );

  Map<String, dynamic> toInsertMap() => {
        'espace_id': espaceId,
        'email': email.trim().toLowerCase(),
        'role': role.valeurBdd,
        'invite_par': inviteParId,
      };
}
