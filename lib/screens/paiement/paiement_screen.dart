import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart';
import '../../models/membre.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

class _Du {
  final Cotisation cotisation;
  final PaiementCotisation paiement;
  double get restant => paiement.montantDu - paiement.montantPaye;
  _Du({required this.cotisation, required this.paiement});
}

class _LigneMembre {
  final Membre membre;
  final List<_Du> dus;
  double get totalDu => dus.fold(0.0, (a, d) => a + d.restant);
  _LigneMembre({required this.membre, required this.dus});
}

/// Recherche d'un membre pour encaisser directement une cotisation due, sans
/// passer par l'écran de détail d'une cotisation précise — reprend
/// `PaiementView` de tresora-app (src/components/paiement/paiement-view.tsx),
/// accessible depuis Cotisations pour les rôles qui gèrent les membres.
class PaiementScreen extends ConsumerStatefulWidget {
  const PaiementScreen({super.key});

  @override
  ConsumerState<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends ConsumerState<PaiementScreen> {
  final _rechercheCtrl = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _rechercheCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membresAsync = ref.watch(membresStreamProvider);
    final cotisationsAsync = ref.watch(cotisationsStreamProvider);
    final paiementsAsync = ref.watch(paiementsEspaceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Recherchez un membre pour encaisser sa cotisation directement, '
              'sans passer par une cotisation précise.',
              style: TextStyle(color: AppColors.texteSecondaire),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rechercheCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un membre…',
              ),
              onChanged: (v) => setState(() => _recherche = v.trim()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: membresAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur : $e')),
                data: (membres) => cotisationsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur : $e')),
                  data: (cotisations) => paiementsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur : $e')),
                    data: (paiements) => _Liste(
                      membres: membres,
                      cotisations: cotisations,
                      paiements: paiements,
                      recherche: _recherche,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Liste extends ConsumerWidget {
  const _Liste(
      {required this.membres,
      required this.cotisations,
      required this.paiements,
      required this.recherche});

  final List<Membre> membres;
  final List<Cotisation> cotisations;
  final List<PaiementCotisation> paiements;
  final String recherche;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cotisationsParId = {for (final c in cotisations) c.id: c};
    final paiementsParMembre = <String, List<PaiementCotisation>>{};
    for (final p in paiements) {
      (paiementsParMembre[p.membreId] ??= []).add(p);
    }

    final lignes = membres.map((membre) {
      final dus = <_Du>[];
      for (final paiement in paiementsParMembre[membre.id] ?? const []) {
        final cotisation = cotisationsParId[paiement.cotisationId];
        if (cotisation == null) continue;
        if (paiement.statut == StatutPaiement.paye ||
            paiement.statut == StatutPaiement.exonere) {
          continue;
        }
        dus.add(_Du(cotisation: cotisation, paiement: paiement));
      }
      return _LigneMembre(membre: membre, dus: dus);
    }).toList();

    final q = recherche.toLowerCase();
    final filtrees = q.isEmpty
        ? lignes
        : lignes
            .where((l) => l.membre.nomComplet.toLowerCase().contains(q))
            .toList();
    filtrees.sort((a, b) => b.totalDu.compareTo(a.totalDu));

    if (filtrees.isEmpty) {
      return const Center(child: Text('Aucun membre trouvé'));
    }

    return ListView.separated(
      itemCount: filtrees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _CarteMembre(ligne: filtrees[i]),
    );
  }
}

class _CarteMembre extends ConsumerStatefulWidget {
  const _CarteMembre({required this.ligne});

  final _LigneMembre ligne;

  @override
  ConsumerState<_CarteMembre> createState() => _CarteMembreState();
}

class _CarteMembreState extends ConsumerState<_CarteMembre> {
  bool _ouvert = false;

  @override
  Widget build(BuildContext context) {
    final ligne = widget.ligne;
    final aDes = ligne.dus.isNotEmpty;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: aDes ? () => setState(() => _ouvert = !_ouvert) : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.indigoProfond,
                    child: Text(
                      ligne.membre.nomComplet.isNotEmpty
                          ? ligne.membre.nomComplet[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ligne.membre.nomComplet,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        if (ligne.membre.telephone.isNotEmpty)
                          Text(ligne.membre.telephone,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.texteSecondaire)),
                      ],
                    ),
                  ),
                  if (ligne.totalDu > 0)
                    Chip(
                      label: Text('${formatMontant(ligne.totalDu)} dû'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.or.withValues(alpha: .15),
                    )
                  else
                    const Chip(
                      label: Text('À jour'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (aDes)
                    Icon(_ouvert ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (_ouvert && aDes)
            Column(
              children: [
                const Divider(height: 1),
                for (final d in ligne.dus)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${d.cotisation.nom} · reste ${formatMontant(d.restant)}',
                            style: const TextStyle(
                                color: AppColors.texteSecondaire),
                          ),
                        ),
                        FilledButton(
                          onPressed: () =>
                              _ouvrirVersement(context, ligne.membre, d),
                          child: const Text('Verser'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _ouvrirVersement(BuildContext context, Membre membre, _Du d) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormulaireVersement(membre: membre, du: d),
    );
  }
}

class _FormulaireVersement extends ConsumerStatefulWidget {
  const _FormulaireVersement({required this.membre, required this.du});

  final Membre membre;
  final _Du du;

  @override
  ConsumerState<_FormulaireVersement> createState() =>
      _FormulaireVersementState();
}

class _FormulaireVersementState extends ConsumerState<_FormulaireVersement> {
  final _formKey = GlobalKey<FormState>();
  final _montantCtrl = TextEditingController();
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
      await ref.read(tranchesServiceProvider).creer(Tranche(
            id: '',
            paiementCotisationId: widget.du.paiement.id,
            date: DateTime.now(),
            montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
            responsable: responsable,
            modePaiement: _mode,
          ));
      ref.invalidate(paiementsEspaceProvider);
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
            Text('Enregistrer un versement',
                style: AppFonts.heading(
                    fontSize: 18, color: AppColors.texteEncre)),
            const SizedBox(height: 4),
            Text(
                '${widget.membre.nomComplet} · ${widget.du.cotisation.nom}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('Reste dû : ${formatMontant(widget.du.restant)}',
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
