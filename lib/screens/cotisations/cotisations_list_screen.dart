import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import 'cotisation_detail_screen.dart';
import 'cotisation_form_screen.dart';

class CotisationsListScreen extends ConsumerWidget {
  const CotisationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cotisationsAsync = ref.watch(cotisationsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cotisations')),
      floatingActionButton: RoleGate(
        peutAcceder: (r) => r.peutGererMembres,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CotisationFormScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle'),
        ),
      ),
      body: cotisationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (cotisations) {
          if (cotisations.isEmpty) return const Center(child: Text('Aucune cotisation'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: cotisations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _CotisationTile(cotisation: cotisations[i]),
          );
        },
      ),
    );
  }
}

class _CotisationTile extends StatelessWidget {
  final Cotisation cotisation;

  const _CotisationTile({required this.cotisation});

  @override
  Widget build(BuildContext context) {
    final enRetard = !cotisation.active
        ? false
        : cotisation.dateLimite.isBefore(DateTime.now());
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.or.withValues(alpha: .15),
          child: const Icon(Icons.savings_outlined, color: AppColors.or),
        ),
        title: Text(cotisation.nom),
        subtitle: Text(
          '${formatMontant(cotisation.montant)} · ${cotisation.periodicite.libelle} · '
          'Échéance ${formatDate(cotisation.dateLimite)}',
        ),
        trailing: !cotisation.active
            ? const Chip(label: Text('Clôturée'), visualDensity: VisualDensity.compact)
            : enRetard
                ? const Chip(
                    label: Text('En retard'),
                    backgroundColor: Color(0x22B34A24),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CotisationDetailScreen(cotisation: cotisation)),
        ),
      ),
    );
  }
}
