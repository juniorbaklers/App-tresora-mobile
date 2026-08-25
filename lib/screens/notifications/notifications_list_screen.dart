import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification.dart';
import '../../providers/auth_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

class NotificationsListScreen extends ConsumerWidget {
  const NotificationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(mesNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                ref
                    .read(notificationsServiceProvider)
                    .marquerToutesLues(user.id);
              }
            },
            child: const Text('Tout marquer lu'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('Aucune notification'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) =>
                _NotificationTile(notification: notifications[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationTresora notification;

  const _NotificationTile({required this.notification});

  IconData get _icone => switch (notification.type) {
        TypeNotification.cotisationRetard => Icons.warning_amber_outlined,
        TypeNotification.nouveauPaiement => Icons.payments_outlined,
        TypeNotification.contributionDemandee => Icons.call_received,
        TypeNotification.contributionRecue => Icons.call_made,
        TypeNotification.evenementBientot => Icons.celebration_outlined,
        TypeNotification.rapportDisponible => Icons.description_outlined,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: notification.lue ? null : AppColors.or.withValues(alpha: .08),
      child: ListTile(
        leading: Icon(_icone,
            color: notification.lue ? AppColors.texteSecondaire : AppColors.or),
        title: Text(notification.titre,
            style: TextStyle(
                fontWeight:
                    notification.lue ? FontWeight.normal : FontWeight.w700)),
        subtitle: Text(
            '${notification.description}\n${formatDate(notification.date)}'),
        isThreeLine: true,
        onTap: notification.lue
            ? null
            : () => ref
                .read(notificationsServiceProvider)
                .marquerLue(notification.id),
      ),
    );
  }
}
