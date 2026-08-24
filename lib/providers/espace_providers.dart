import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/espace.dart';
import '../models/role.dart';
import '../services/espaces_service.dart';
import 'auth_providers.dart';

final espacesServiceProvider = Provider((ref) => EspacesService());

/// "Mes espaces" en temps réel — se met à jour si on est ajouté/retiré
/// d'un espace, ou si notre rôle y change.
final mesEspacesProvider = StreamProvider<List<EspaceAvecRole>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(<EspaceAvecRole>[]);
  return ref.watch(espacesServiceProvider).streamMesEspaces(user.id);
});

/// Espace actuellement sélectionné (null = aucun espace choisi, l'app
/// affiche l'écran de sélection).
final currentEspaceIdProvider = StateProvider<String?>((ref) => null);

/// L'espace courant avec le rôle de l'utilisateur dedans, dérivé de
/// mesEspacesProvider + currentEspaceIdProvider.
final currentEspaceProvider = Provider<EspaceAvecRole?>((ref) {
  final id = ref.watch(currentEspaceIdProvider);
  if (id == null) return null;
  final espaces = ref.watch(mesEspacesProvider).valueOrNull ?? [];
  for (final e in espaces) {
    if (e.espace.id == id) return e;
  }
  return null;
});

/// Rôle dans l'espace courant — `membre` (le plus restrictif) par défaut
/// tant qu'aucun espace n'est sélectionné.
final currentRoleProvider = Provider<RoleEspace>((ref) {
  return ref.watch(currentEspaceProvider)?.role ?? RoleEspace.membre;
});
