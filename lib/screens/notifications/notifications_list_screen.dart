import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/notification.dart';
import '../../providers/auth_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/erreurs.dart';

/// Habillage cohérent avec le reste de la refonte : cartes plates
/// bordées, pastille d'icône colorée pour les notifications non lues.
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
        error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text('Aucune notification',
                  style: TextStyle(color: AppColors.texteSecondaire)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
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
    final nonLue = !notification.lue;
    return Material(
      color: nonLue ? AppColors.or.withValues(alpha: .07) : AppColors.carte,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: nonLue
            ? () => ref
                .read(notificationsServiceProvider)
                .marquerLue(notification.id)
            : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: nonLue ? AppColors.or : AppColors.bordure),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: nonLue
                      ? AppColors.or.withValues(alpha: .18)
                      : AppColors.fond,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_icone,
                    size: 19,
                    color:
                        nonLue ? AppColors.or : AppColors.texteSecondaire),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.titre,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                nonLue ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.texteEncre)),
                    const SizedBox(height: 3),
                    Text(notification.description,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.texteSecondaire)),
                    const SizedBox(height: 5),
                    Text(formatDate(notification.date),
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.texteSecondaire)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
