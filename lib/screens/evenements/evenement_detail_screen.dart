import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart' show ModePaiement;
import '../../models/evenement.dart';
import '../../models/membre.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';

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
            error: (e, _) => Text('Erreur : $e',
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

class _FormulaireCollecte extends ConsumerStatefulWidget {
  final Evenement evenement;

  const _FormulaireCollecte({required this.evenement});

  @override
  ConsumerState<_FormulaireCollecte> createState() =>
      _FormulaireCollecteState();
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
      final nom = _nomCtrl.text.trim();
      final responsable = ref.read(currentUserProvider)?.email ?? '';
      await ref
          .read(contributionsEvenementServiceProvider)
          .creer(ContributionEvenement(
            id: '',
            evenementId: widget.evenement.id,
            nomContributeur: nom,
            montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
            modePaiement: _mode,
            responsable: responsable,
            date: DateTime.now(),
          ));
      if (mounted) await _proposerAjoutMembre(nom);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Enregistrement impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// Si le contributeur saisi ne correspond à aucun membre existant de
  /// l'espace, propose de l'ajouter au registre des membres — pour qu'un
  /// donateur régulier ne reste pas invisible du suivi des cotisations.
  Future<void> _proposerAjoutMembre(String nom) async {
    final espaceId = widget.evenement.espaceId;
    final membres = ref.read(membresStreamProvider).valueOrNull ?? [];
    final dejaMembre = membres
        .any((m) => m.nomComplet.trim().toLowerCase() == nom.toLowerCase());
    if (dejaMembre) return;

    final ajouter = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter comme membre ?'),
        content: Text(
            "$nom n'est pas encore membre de cet espace. L'ajouter au registre des membres ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non merci'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (ajouter != true || !mounted) return;

    final parts = nom.split(RegExp(r'\s+'));
    final prenom = parts.first;
    final nomFamille = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    await ref.read(membresServiceProvider).creer(Membre(
          id: '',
          espaceId: espaceId,
          nom: nomFamille,
          prenom: prenom,
          telephone: '',
          actif: true,
        ));
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
            Text('Enregistrer une contribution',
                style: AppFonts.heading(
                    fontSize: 18, color: AppColors.texteEncre)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomCtrl,
              textCapitalization: TextCapitalization.words,
              decoration:
                  const InputDecoration(labelText: 'Nom du contributeur'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _montantCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Montant reçu (FCFA)'),
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
                  .map(
                      (m) => DropdownMenuItem(value: m, child: Text(m.libelle)))
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
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }
}
