import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contribution.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';

class ContributionDetailScreen extends ConsumerWidget {
  final Contribution contribution;
  final bool estCible;

  const ContributionDetailScreen(
      {super.key, required this.contribution, required this.estCible});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versementsAsync =
        ref.watch(versementsContributionProvider(contribution.id));
    final autreEspace = estCible
        ? contribution.nomEspaceDemandeur
        : contribution.nomEspaceCible;

    return Scaffold(
      appBar: AppBar(title: Text(contribution.projet)),
      floatingActionButton: estCible
          ? RoleGate(
              peutAcceder: (r) => r.peutGerer,
              child: FloatingActionButton.extended(
                onPressed: () => _ouvrirAjoutVersement(context),
                icon: const Icon(Icons.add),
                label: const Text('Verser'),
              ),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (contribution.description.isNotEmpty) ...[
            Text(contribution.description,
                style: const TextStyle(color: AppColors.texteSecondaire)),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                  child: _Resume(
                      titre: 'Reçu',
                      montant: contribution.montantRecu,
                      couleur: AppColors.palme)),
              const SizedBox(width: 12),
              Expanded(
                  child: _Resume(
                      titre: 'Demandé', montant: contribution.montantDemande)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: contribution.progression,
              minHeight: 8,
              backgroundColor: AppColors.bordure,
              color: AppColors.palme,
            ),
          ),
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
                  icone: estCible ? Icons.call_received : Icons.call_made,
                  titre: estCible ? 'Demandé par' : 'Demandé à',
                  valeur: autreEspace ?? '—',
                ),
                const Divider(height: 1, color: AppColors.bordure),
                _LigneInfo(
                  icone: Icons.event_outlined,
                  titre: 'Échéance',
                  valeur: formatDate(contribution.dateLimite),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('VERSEMENTS',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.texteSecondaire,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          versementsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erreur : $e'),
            data: (versements) {
              if (versements.isEmpty) {
                return const Text('Aucun versement enregistré',
                    style: TextStyle(color: AppColors.texteSecondaire));
              }
              return Column(
                children: [
                  for (final v in versements) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.carte,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.bordure),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.palme.withValues(alpha: .13),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(Icons.arrow_downward,
                                color: AppColors.palme, size: 16),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(formatMontant(v.montant),
                                style: AppFonts.montant(
                                    fontSize: 13,
                                    color: AppColors.texteEncre)),
                          ),
                          Text(formatDate(v.date),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.texteSecondaire)),
                        ],
                      ),
                    ),
                    if (v != versements.last) const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _ouvrirAjoutVersement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormulaireVersement(contribution: contribution),
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

class _FormulaireVersement extends ConsumerStatefulWidget {
  final Contribution contribution;

  const _FormulaireVersement({required this.contribution});

  @override
  ConsumerState<_FormulaireVersement> createState() =>
      _FormulaireVersementState();
}

class _FormulaireVersementState extends ConsumerState<_FormulaireVersement> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(contributionsServiceProvider).enregistrerVersement(
            widget.contribution.id,
            double.parse(_montantCtrl.text.replaceAll(',', '.')),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Enregistrement impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final restant =
        widget.contribution.montantDemande - widget.contribution.montantRecu;
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
            Text('Enregistrer un versement',
                style: AppFonts.heading(
                    fontSize: 18, color: AppColors.texteEncre)),
            const SizedBox(height: 4),
            Text('Reste dû : ${formatMontant(restant)}',
                style: const TextStyle(color: AppColors.texteSecondaire)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _montantCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Montant versé (FCFA)'),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                return (n == null || n <= 0) ? 'Montant invalide' : null;
              },
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
