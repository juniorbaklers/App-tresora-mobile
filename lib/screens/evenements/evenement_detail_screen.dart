import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/evenement.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import 'contribution_evenement_form_screen.dart';
import '../../utils/erreurs.dart';

class EvenementDetailScreen extends ConsumerStatefulWidget {
  final Evenement evenement;

  const EvenementDetailScreen({super.key, required this.evenement});

  @override
  ConsumerState<EvenementDetailScreen> createState() =>
      _EvenementDetailScreenState();
}

class _EvenementDetailScreenState extends ConsumerState<EvenementDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final evenements = ref.watch(evenementsStreamProvider).valueOrNull ?? [];
    final evenement = evenements.firstWhere(
      (e) => e.id == widget.evenement.id,
      orElse: () => widget.evenement,
    );
    final progression = evenement.progression;
    final contributionsAsync =
        ref.watch(contributionsEvenementProvider(evenement.id));

    return Scaffold(
      appBar: AppBar(title: Text(evenement.nom)),
      floatingActionButton: RoleGate(
        peutAcceder: (r) => r.peutGererMembres,
        child: FloatingActionButton.extended(
          onPressed: () => _ouvrirAjoutCollecte(context),
          icon: const Icon(Icons.add),
          label: const Text('Contribution'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (evenement.description.isNotEmpty) ...[
            Text(evenement.description,
                style: const TextStyle(color: AppColors.texteSecondaire)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _Resume(
                    titre: 'Collecté',
                    montant: evenement.montantCollecte,
                    couleur: AppColors.palme),
              ),
              if (evenement.montantCible != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _Resume(
                      titre: 'Objectif', montant: evenement.montantCible!),
                ),
              ],
            ],
          ),
          if (progression != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progression.clamp(0, 1),
                minHeight: 8,
                backgroundColor: AppColors.bordure,
                color: AppColors.palme,
              ),
            ),
            const SizedBox(height: 4),
            Text(
                '${(progression * 100).clamp(0, 999).toStringAsFixed(0)} % de l\'objectif',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.texteSecondaire)),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.carte,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Column(
              children: [
                _LigneInfo(
                  icone: Icons.calendar_today_outlined,
                  titre: 'Période',
                  valeur:
                      '${formatDate(evenement.dateDebut)} → ${formatDate(evenement.dateFin)}',
                ),
                const Divider(height: 1, color: AppColors.bordure),
                _LigneInfo(
                  icone: Icons.groups_outlined,
                  titre: 'Participants',
                  valeur: '${evenement.participants}',
                ),
                if (evenement.montantSuggere != null) ...[
                  const Divider(height: 1, color: AppColors.bordure),
                  _LigneInfo(
                    icone: Icons.sell_outlined,
                    titre: 'Montant suggéré par personne',
                    valeur: formatMontant(evenement.montantSuggere!),
                  ),
                ],
                const Divider(height: 1, color: AppColors.bordure),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined,
                          size: 18, color: AppColors.texteSecondaire),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('Statut',
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.texteSecondaire)),
                      ),
                      Text(evenement.statut.libelle,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.texteEncre)),
                      RoleGate(
                        peutAcceder: (r) => r.peutGererMembres,
                        child: PopupMenuButton<StatutEvenement>(
                          onSelected: (statut) => ref
                              .read(evenementsServiceProvider)
                              .changerStatut(evenement.id, statut),
                          itemBuilder: (_) => StatutEvenement.values
                              .map((s) =>
                                  PopupMenuItem(value: s, child: Text(s.libelle)))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Contributions',
              style:
                  AppFonts.heading(fontSize: 16, color: AppColors.texteEncre)),
          const SizedBox(height: 8),
          contributionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Erreur : ${messageErreur(e)}',
                style: const TextStyle(color: AppColors.terre)),
            data: (contributions) {
              if (contributions.isEmpty) {
                return const Text(
                    'Aucune contribution enregistrée pour le moment',
                    style: TextStyle(color: AppColors.texteSecondaire));
              }
              return Column(
                children: [
                  for (final contribution in contributions)
                    _LigneContribution(contribution: contribution),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _ouvrirAjoutCollecte(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ContributionEvenementFormScreen(evenement: widget.evenement),
      ),
    );
  }
}

class _Resume extends StatelessWidget {
  final String titre;
  final double montant;
  final Color couleur;

  const _Resume(
      {required this.titre,
      required this.montant,
      this.couleur = AppColors.graphite});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.texteSecondaire)),
          const SizedBox(height: 4),
          Text(formatMontant(montant),
              style: AppFonts.montant(fontSize: 16, color: couleur)),
        ],
      ),
    );
  }
}

class _LigneInfo extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String valeur;

  const _LigneInfo(
      {required this.icone, required this.titre, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icone, size: 18, color: AppColors.texteSecondaire),
          const SizedBox(width: 12),
          Expanded(
            child: Text(titre,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.texteSecondaire)),
          ),
          Text(valeur,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texteEncre)),
        ],
      ),
    );
  }
}

/// Une fiche de contribution : qui a donné, combien, comment et quand.
class _LigneContribution extends StatelessWidget {
  final ContributionEvenement contribution;

  const _LigneContribution({required this.contribution});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contribution.nomContributeur,
                    style: AppFonts.heading(
                        fontSize: 13, color: AppColors.texteEncre)),
                const SizedBox(height: 3),
                Text(
                    '${contribution.modePaiement.libelle} · ${formatDate(contribution.date)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.texteSecondaire)),
              ],
            ),
          ),
          Text(formatMontant(contribution.montant),
              style: AppFonts.montant(
                  fontSize: 14, color: AppColors.texteEncre)),
        ],
      ),
    );
  }
}

