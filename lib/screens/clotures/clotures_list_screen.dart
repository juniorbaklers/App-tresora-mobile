import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cloture.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import 'cloture_form_screen.dart';

class CloturesListScreen extends ConsumerWidget {
  const CloturesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloturesAsync = ref.watch(cloturesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Clôtures')),
      floatingActionButton: RoleGate(
        peutAcceder: (r) => r.peutGerer,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ClotureFormScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle'),
        ),
      ),
      body: cloturesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (clotures) {
          if (clotures.isEmpty) return const Center(child: Text('Aucune clôture enregistrée'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: clotures.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) => _ClotureTile(cloture: clotures[i]),
          );
        },
      ),
    );
  }
}

class _ClotureTile extends StatelessWidget {
  final Cloture cloture;

  const _ClotureTile({required this.cloture});

  @override
  Widget build(BuildContext context) {
    final ecart = cloture.ecart;
    final couleurEcart = ecart == 0 ? AppColors.palme : AppColors.terre;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.fact_check_outlined),
        title: Text(cloture.culte.isEmpty ? formatDate(cloture.date) : '${cloture.culte} · ${formatDate(cloture.date)}'),
        subtitle: Text('Compté ${formatMontant(cloture.totalCompte)} · Déclaré ${formatMontant(cloture.totalDeclare)}'),
        trailing: Text(
          ecart == 0 ? 'OK' : '${ecart > 0 ? '+' : ''}${formatMontant(ecart)}',
          style: TextStyle(color: couleurEcart, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
