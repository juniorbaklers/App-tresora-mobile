import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contribution.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import 'contribution_detail_screen.dart';
import 'contribution_form_screen.dart';

class ContributionsListScreen extends ConsumerWidget {
  const ContributionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envoyeesAsync = ref.watch(contributionsEnvoyeesStreamProvider);
    final recuesAsync = ref.watch(contributionsRecuesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Contributions inter-espaces')),
      floatingActionButton: RoleGate(
        peutAcceder: (r) => r.peutGerer,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ContributionFormScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Demander'),
        ),
      ),
      body: envoyeesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (envoyees) => recuesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (recues) {
            if (envoyees.isEmpty && recues.isEmpty) {
              return const Center(child: Text('Aucune contribution inter-espaces'));
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (recues.isNotEmpty) ...[
                  const _EnTeteSection(titre: 'DEMANDÉES PAR D\'AUTRES ESPACES'),
                  for (final c in recues) _ContributionTile(contribution: c, estCible: true),
                  const SizedBox(height: 16),
                ],
                if (envoyees.isNotEmpty) ...[
                  const _EnTeteSection(titre: 'MES DEMANDES'),
                  for (final c in envoyees) _ContributionTile(contribution: c, estCible: false),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EnTeteSection extends StatelessWidget {
  final String titre;

  const _EnTeteSection({required this.titre});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(titre, style: const TextStyle(fontSize: 11, color: AppColors.texteSecondaire, fontWeight: FontWeight.w700)),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  final Contribution contribution;
  final bool estCible;

  const _ContributionTile({required this.contribution, required this.estCible});

  Color get _couleurStatut => switch (contribution.statut) {
        StatutContribution.paye => AppColors.palme,
        StatutContribution.partiel => AppColors.or,
        StatutContribution.enAttente => AppColors.texteSecondaire,
      };

  @override
  Widget build(BuildContext context) {
    final autreEspace = estCible ? contribution.nomEspaceDemandeur : contribution.nomEspaceCible;
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ContributionDetailScreen(contribution: contribution, estCible: estCible)),
        ),
        title: Text(contribution.projet),
        subtitle: Text(
          '${estCible ? 'Demandé par' : 'Demandé à'} ${autreEspace ?? '—'} · Échéance ${formatDate(contribution.dateLimite)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${formatMontant(contribution.montantRecu)} / ${formatMontant(contribution.montantDemande)}',
                style: AppFonts.montant(fontSize: 13, color: AppColors.texteEncre)),
            const SizedBox(height: 4),
            Chip(
              label: Text(contribution.statut.libelle),
              backgroundColor: _couleurStatut.withValues(alpha: .15),
              labelStyle: TextStyle(color: _couleurStatut, fontSize: 11),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
