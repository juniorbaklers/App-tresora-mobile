import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/espace.dart';
import '../models/invitation.dart';
import '../models/membre_compte.dart';
import '../models/notification.dart';
import '../models/role.dart';
import '../services/espaces_service.dart';
import '../services/invitations_service.dart';
import '../services/notifications_service.dart';
import 'auth_providers.dart';

final espacesServiceProvider = Provider((ref) => EspacesService());
final invitationsServiceProvider = Provider((ref) => InvitationsService());
final notificationsServiceProvider = Provider((ref) => NotificationsService());

/// Invitations en attente adressées à l'utilisateur connecté, tous
/// espaces confondus — affichées sur l'écran de sélection d'espace.
final mesInvitationsProvider = StreamProvider<List<Invitation>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || user.email == null) return Stream.value(<Invitation>[]);
  return ref
      .watch(invitationsServiceProvider)
      .streamMesInvitations(user.email!);
});

/// Notifications de l'utilisateur connecté, tous espaces confondus.
final mesNotificationsProvider =
    StreamProvider<List<NotificationTresora>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(<NotificationTresora>[]);
  return ref
      .watch(notificationsServiceProvider)
      .streamMesNotifications(user.id);
});

/// Comptes utilisateurs + rôles de l'espace courant — gestion des rôles
/// dans Réglages.
final membresCompteStreamProvider = StreamProvider<List<MembreCompte>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<MembreCompte>[]);
  return ref.watch(espacesServiceProvider).streamMembresCompte(espaceId);
});

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
