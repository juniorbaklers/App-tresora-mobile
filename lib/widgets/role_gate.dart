import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/role.dart';
import '../providers/espace_providers.dart';

/// N'affiche `child` que si le rôle de l'utilisateur dans l'espace courant
/// satisfait [peutAcceder]. Purement cosmétique : la vraie barrière de
/// sécurité est la Row Level Security côté Supabase (supabase/schema_3_rls.sql)
/// — un appel direct à l'API resterait bloqué même si ce widget était
/// contourné.
class RoleGate extends ConsumerWidget {
  final bool Function(RoleEspace role) peutAcceder;
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
    final role = ref.watch(currentRoleProvider);
    if (peutAcceder(role)) return child;
    return remplacement ?? const SizedBox.shrink();
  }
}
