import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivite_provider.dart';
import '../theme/app_theme.dart';

/// Bandeau discret affiché quand aucune connexion réseau n'est détectée —
/// les écrans continuent d'afficher les dernières données mises en cache
/// (voir lib/utils/cache_hors_ligne.dart) plutôt que de planter.
class BandeauHorsLigne extends ConsumerWidget {
  const BandeauHorsLigne({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horsLigne = ref.watch(estHorsLigneProvider).valueOrNull ?? false;
    if (!horsLigne) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: AppColors.or.withValues(alpha: .18),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 14, color: AppColors.texteEncre),
          const SizedBox(width: 6),
          Text(
            'Hors-ligne — dernières données synchronisées',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.texteEncre.withValues(alpha: .8)),
          ),
        ],
      ),
    );
  }
}
