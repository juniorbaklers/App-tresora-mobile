import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import '../paiement/paiement_screen.dart';
import 'cotisation_detail_screen.dart';
import 'cotisation_form_screen.dart';
import '../../utils/erreurs.dart';

class CotisationsListScreen extends ConsumerWidget {
  const CotisationsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cotisationsAsync = ref.watch(cotisationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotisations'),
        actions: [
          RoleGate(
            peutAcceder: (r) => r.peutGererMembres,
            child: IconButton(
              icon: const Icon(Icons.point_of_sale_outlined),
              tooltip: 'Paiement',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaiementScreen()),
              ),
            ),
          ),
        ],
      ),
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
        error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
        data: (cotisations) {
          if (cotisations.isEmpty) {
            return const Center(child: Text('Aucune cotisation'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cotisations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _CotisationTile(cotisation: cotisations[i]),
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
    return Material(
      color: AppColors.carte,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => CotisationDetailScreen(cotisation: cotisation)),
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
                  color: AppColors.or.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.savings_outlined,
                    size: 19, color: AppColors.or),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cotisation.nom,
                        style: AppFonts.heading(
                            fontSize: 13, color: AppColors.texteEncre)),
                    const SizedBox(height: 3),
                    Text(
                      '${formatMontant(cotisation.montant)} · ${cotisation.periodicite.libelle} · '
                      'Échéance ${formatDate(cotisation.dateLimite)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.texteSecondaire),
                    ),
                  ],
                ),
              ),
              if (!cotisation.active || enRetard) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: !cotisation.active
                        ? AppColors.texteSecondaire.withValues(alpha: .13)
                        : AppColors.terre.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(!cotisation.active ? 'Clôturée' : 'En retard',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: !cotisation.active
                              ? AppColors.texteSecondaire
                              : AppColors.terre)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
