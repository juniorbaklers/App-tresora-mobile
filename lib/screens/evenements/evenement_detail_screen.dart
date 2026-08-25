import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart' show ModePaiement;
import '../../models/evenement.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';

class EvenementDetailScreen extends ConsumerStatefulWidget {
  final Evenement evenement;

  const EvenementDetailScreen({super.key, required this.evenement});

  @override
  ConsumerState<EvenementDetailScreen> createState() => _EvenementDetailScreenState();
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
    final contributionsAsync = ref.watch(contributionsEvenementProvider(evenement.id));

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
            Text(evenement.description, style: const TextStyle(color: AppColors.texteSecondaire)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: _Resume(titre: 'Collecté', montant: evenement.montantCollecte, couleur: AppColors.palme),
              ),
              if (evenement.montantCible != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _Resume(titre: 'Objectif', montant: evenement.montantCible!),
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
            Text('${(progression * 100).clamp(0, 999).toStringAsFixed(0)} % de l\'objectif',
                style: const TextStyle(fontSize: 12, color: AppColors.texteSecondaire)),
          ],
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Période'),
            subtitle: Text('${formatDate(evenement.dateDebut)} → ${formatDate(evenement.dateFin)}'),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.groups_outlined),
            title: const Text('Participants'),
            subtitle: Text('${evenement.participants}'),
          ),
          if (evenement.montantSuggere != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.sell_outlined),
              title: const Text('Montant suggéré par personne'),
              subtitle: Text(formatMontant(evenement.montantSuggere!)),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Statut'),
            subtitle: Text(evenement.statut.libelle),
            trailing: RoleGate(
              peutAcceder: (r) => r.peutGererMembres,
              child: PopupMenuButton<StatutEvenement>(
                onSelected: (statut) =>
                    ref.read(evenementsServiceProvider).changerStatut(evenement.id, statut),
                itemBuilder: (_) => StatutEvenement.values
                    .map((s) => PopupMenuItem(value: s, child: Text(s.libelle)))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Contributions', style: AppFonts.heading(fontSize: 16, color: AppColors.texteEncre)),
          const SizedBox(height: 8),
          contributionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Erreur : $e', style: const TextStyle(color: AppColors.terre)),
            data: (contributions) {
              if (contributions.isEmpty) {
                return const Text('Aucune contribution enregistrée pour le moment',
                    style: TextStyle(color: AppColors.texteSecondaire));
              }
              return Column(
                children: [
                  for (final contribution in contributions) _LigneContribution(contribution: contribution),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _ouvrirAjoutCollecte(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormulaireCollecte(evenement: widget.evenement),
    );
  }
}

class _Resume extends StatelessWidget {
  final String titre;
  final double montant;
  final Color couleur;

  const _Resume({required this.titre, required this.montant, this.couleur = AppColors.indigoProfond});

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
          Text(titre.toUpperCase(), style: const TextStyle(fontSize: 11, color: AppColors.texteSecondaire)),
          const SizedBox(height: 4),
          Text(formatMontant(montant), style: AppFonts.montant(fontSize: 16, color: couleur)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        title: Text(contribution.nomContributeur),
        subtitle: Text('${contribution.modePaiement.libelle} · ${formatDate(contribution.date)}'),
        trailing: Text(formatMontant(contribution.montant), style: AppFonts.montant(fontSize: 14)),
      ),
    );
  }
}

class _FormulaireCollecte extends ConsumerStatefulWidget {
  final Evenement evenement;

  const _FormulaireCollecte({required this.evenement});

  @override
  ConsumerState<_FormulaireCollecte> createState() => _FormulaireCollecteState();
}

class _FormulaireCollecteState extends ConsumerState<_FormulaireCollecte> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  late final _montantCtrl = TextEditingController(
    text: widget.evenement.montantSuggere?.toStringAsFixed(0) ?? '',
  );
  ModePaiement _mode = ModePaiement.especes;
  bool _enCours = false;
  String? _erreur;

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final responsable = ref.read(currentUserProvider)?.email ?? '';
      await ref.read(contributionsEvenementServiceProvider).creer(ContributionEvenement(
            id: '',
            evenementId: widget.evenement.id,
            nomContributeur: _nomCtrl.text.trim(),
            montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
            modePaiement: _mode,
            responsable: responsable,
            date: DateTime.now(),
          ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Enregistrement impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enregistrer une contribution', style: AppFonts.heading(fontSize: 18, color: AppColors.texteEncre)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom du contributeur'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _montantCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Montant reçu (FCFA)'),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                return (n == null || n <= 0) ? 'Montant invalide' : null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<ModePaiement>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Mode de paiement'),
              items: ModePaiement.values
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.libelle)))
                  .toList(),
              onChanged: (v) => setState(() => _mode = v!),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: const TextStyle(color: AppColors.terre)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enCours ? null : _enregistrer,
              child: _enCours
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }
}
