import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contribution.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import 'contribution_detail_screen.dart';
import 'contribution_form_screen.dart';
import '../../utils/erreurs.dart';

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
        error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
        data: (envoyees) => recuesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
          data: (recues) {
            if (envoyees.isEmpty && recues.isEmpty) {
              return const Center(
                  child: Text('Aucune contribution inter-espaces'));
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (recues.isNotEmpty) ...[
                  const _EnTeteSection(
                      titre: 'DEMANDÉES PAR D\'AUTRES ESPACES'),
                  for (final c in recues)
                    _ContributionTile(contribution: c, estCible: true),
                  const SizedBox(height: 16),
                ],
                if (envoyees.isNotEmpty) ...[
                  const _EnTeteSection(titre: 'MES DEMANDES'),
                  for (final c in envoyees)
                    _ContributionTile(contribution: c, estCible: false),
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
      child: Text(titre,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.texteSecondaire,
              fontWeight: FontWeight.w700)),
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
    final autreEspace = estCible
        ? contribution.nomEspaceDemandeur
        : contribution.nomEspaceCible;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ContributionDetailScreen(
                    contribution: contribution, estCible: estCible)),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
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
                  child: Icon(
                      estCible ? Icons.call_received : Icons.call_made,
                      size: 19,
                      color: AppColors.texteSecondaire),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contribution.projet,
                          style: AppFonts.heading(
                              fontSize: 13, color: AppColors.texteEncre)),
                      const SizedBox(height: 3),
                      Text(
                        '${estCible ? 'Demandé par' : 'Demandé à'} ${autreEspace ?? '—'} · Échéance ${formatDate(contribution.dateLimite)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.texteSecondaire),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                        '${formatMontant(contribution.montantRecu)} / ${formatMontant(contribution.montantDemande)}',
                        style: AppFonts.montant(
                            fontSize: 12, color: AppColors.texteEncre)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _couleurStatut.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(contribution.statut.libelle,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _couleurStatut)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
