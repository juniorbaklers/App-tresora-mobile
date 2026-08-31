import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entree_journal.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/erreurs.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal d\'audit')),
      body: journalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
        data: (entrees) {
          if (entrees.isEmpty) {
            return const Center(child: Text('Aucune entrée pour l\'instant'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entrees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _EntreeTile(entree: entrees[i]),
          );
        },
      ),
    );
  }
}

class _EntreeTile extends StatelessWidget {
  final EntreeJournal entree;

  const _EntreeTile({required this.entree});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.fond,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.history,
                size: 19, color: AppColors.texteSecondaire),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entree.action,
                    style: AppFonts.heading(
                        fontSize: 13, color: AppColors.texteEncre)),
                const SizedBox(height: 3),
                Text(
                  '${entree.utilisateur.isEmpty ? 'Système' : entree.utilisateur}'
                  '${entree.role.isEmpty ? '' : ' · ${entree.role}'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.texteSecondaire),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDate(entree.date)} à ${entree.heure}',
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.texteSecondaire),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
