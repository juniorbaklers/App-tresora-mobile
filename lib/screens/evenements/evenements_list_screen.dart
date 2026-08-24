import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/evenement.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/motif.dart';
import '../../widgets/role_gate.dart';
import 'evenement_detail_screen.dart';
import 'evenement_form_screen.dart';

class EvenementsListScreen extends ConsumerWidget {
  const EvenementsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evenementsAsync = ref.watch(evenementsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Événements')),
      floatingActionButton: RoleGate(
        peutAcceder: (r) => r.peutGererMembres,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EvenementFormScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nouveau'),
        ),
      ),
      body: evenementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (evenements) {
          if (evenements.isEmpty) return const Center(child: Text('Aucun événement'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: evenements.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _EvenementTile(evenement: evenements[i]),
          );
        },
      ),
    );
  }
}

class _EvenementTile extends StatelessWidget {
  final Evenement evenement;

  const _EvenementTile({required this.evenement});

  Tonalite get _tonalite => switch (evenement.statut) {
        StatutEvenement.planifie => Tonalite.indigo,
        StatutEvenement.actif => Tonalite.or,
        StatutEvenement.termine => Tonalite.palme,
      };

  @override
  Widget build(BuildContext context) {
    final progression = evenement.progression;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EvenementDetailScreen(evenement: evenement)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BandeTissee(tonalite: _tonalite),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(evenement.nom, style: AppFonts.heading(fontSize: 16, color: AppColors.texteEncre)),
                  ),
                  Chip(
                    label: Text(evenement.statut.libelle),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${formatDate(evenement.dateDebut)} → ${formatDate(evenement.dateFin)}',
                style: const TextStyle(fontSize: 12, color: AppColors.texteSecondaire),
              ),
              const SizedBox(height: 10),
              Text(
                evenement.montantCible != null
                    ? '${formatMontant(evenement.montantCollecte)} / ${formatMontant(evenement.montantCible!)}'
                    : formatMontant(evenement.montantCollecte),
                style: AppFonts.montant(fontSize: 16, color: AppColors.texteEncre),
              ),
              if (progression != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progression.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: AppColors.bordure,
                    color: AppColors.palme,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                '${evenement.participants} participant${evenement.participants > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.texteSecondaire),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
