import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entree_journal.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

class JournalListScreen extends ConsumerWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journalAsync = ref.watch(journalStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Journal d\'audit')),
      body: journalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (entrees) {
          if (entrees.isEmpty) {
            return const Center(child: Text('Aucune entrée pour l\'instant'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entrees.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
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
    return Card(
      child: ListTile(
        leading: const Icon(Icons.history, color: AppColors.texteSecondaire),
        title: Text(entree.action),
        subtitle: Text(
          '${entree.utilisateur.isEmpty ? 'Système' : entree.utilisateur}'
          '${entree.role.isEmpty ? '' : ' · ${entree.role}'}\n'
          '${formatDate(entree.date)} à ${entree.heure}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
