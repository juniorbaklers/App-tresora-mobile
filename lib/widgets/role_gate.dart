import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/role.dart';
import '../providers/auth_providers.dart';

/// N'affiche `child` que si le profil courant satisfait [peutAcceder].
/// Purement cosmétique : la vraie barrière de sécurité est la Row Level
/// Security côté Supabase (schema.sql / schema_4_cloture.sql) — un appel
/// direct à l'API resterait bloqué même si ce widget était contourné.
class RoleGate extends ConsumerWidget {
  final bool Function(RoleUtilisateur role) peutAcceder;
  final Widget child;
  final Widget? remplacement;

  const RoleGate({
    super.key,
    required this.peutAcceder,
    required this.child,
    this.remplacement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(monProfilProvider).valueOrNull;
    if (profil != null && peutAcceder(profil.role)) return child;
    return remplacement ?? const SizedBox.shrink();
  }
}
