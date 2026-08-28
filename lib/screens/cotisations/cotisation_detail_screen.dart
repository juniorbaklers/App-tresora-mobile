import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart';
import '../../models/membre.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';

class CotisationDetailScreen extends ConsumerWidget {
  final Cotisation cotisation;

  const CotisationDetailScreen({super.key, required this.cotisation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paiementsAsync =
        ref.watch(paiementsCotisationProvider(cotisation.id));
    final membres = ref.watch(membresStreamProvider).valueOrNull ?? [];
    final membresParId = {for (final m in membres) m.id: m};

    return Scaffold(
      appBar: AppBar(
        title: Text(cotisation.nom),
        actions: [
          RoleGate(
            peutAcceder: (r) => r.peutGererMembres,
            child: IconButton(
              icon: const Icon(Icons.person_add_alt),
              tooltip: 'Ajouter des membres',
              onPressed: () {
                final dejaInclus = (ref
                            .read(paiementsCotisationProvider(cotisation.id))
                            .valueOrNull ??
                        [])
                    .map((p) => p.membreId)
                    .toSet();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => _DialogueAjouterMembres(
                    cotisation: cotisation,
                    membres: membres,
                    dejaInclus: dejaInclus,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: paiementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (paiements) {
          if (paiements.isEmpty) {
            return const Center(
                child: Text('Aucun membre assigné à cette cotisation'));
          }
          final totalDu = paiements.fold(0.0, (a, p) => a + p.montantDu);
          final totalPaye = paiements.fold(0.0, (a, p) => a + p.montantPaye);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _Resume(titre: 'Attendu', montant: totalDu),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Resume(
                          titre: 'Collecté',
                          montant: totalPaye,
                          couleur: AppColors.palme),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: paiements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final paiement = paiements[i];
                    final membre = membresParId[paiement.membreId];
                    return _LignePaiement(
                      nomMembre: membre?.nomComplet ?? 'Membre inconnu',
                      paiement: paiement,
                    );
                  },
                ),
              ),
            ],
          );
        },
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

/// Ajoute des membres qui ne font pas encore partie de cette cotisation
/// (ligne paiements_cotisation à zéro, statut impayé) — pour un membre
/// arrivé après coup. Reprend `AjouterMembresDialog` de tresora-app.
class _DialogueAjouterMembres extends ConsumerStatefulWidget {
  final Cotisation cotisation;
  final List<Membre> membres;
  final Set<String> dejaInclus;

  const _DialogueAjouterMembres({
    required this.cotisation,
    required this.membres,
    required this.dejaInclus,
  });

  @override
  ConsumerState<_DialogueAjouterMembres> createState() =>
      _DialogueAjouterMembresState();
}

class _DialogueAjouterMembresState
    extends ConsumerState<_DialogueAjouterMembres> {
  String _recherche = '';
  final Set<String> _selectionnes = {};
  bool _enCours = false;
  String? _erreur;

  Future<void> _valider() async {
    if (_selectionnes.isEmpty) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(cotisationsServiceProvider).ajouterMembres(
          widget.cotisation.id,
          widget.cotisation.montant,
          _selectionnes.toList());
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Ajout impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = widget.membres
        .where((m) => !widget.dejaInclus.contains(m.id))
        .where((m) =>
            _recherche.isEmpty ||
            m.nomComplet.toLowerCase().contains(_recherche.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Ajouter des membres',
              style:
                  AppFonts.heading(fontSize: 18, color: AppColors.texteEncre)),
          const SizedBox(height: 4),
          const Text(
            'Seuls les membres qui n\'en font pas encore partie sont proposés.',
            style: TextStyle(fontSize: 12, color: AppColors.texteSecondaire),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un membre…'),
            onChanged: (v) => setState(() => _recherche = v.trim()),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: widget.membres.isEmpty
                ? const Center(
                    child: Text('Cet espace n\'a encore aucun membre.',
                        style: TextStyle(color: AppColors.texteSecondaire)))
                : disponibles.isEmpty
                    ? Center(
                        child: Text(
                          _recherche.isNotEmpty
                              ? 'Aucun membre trouvé.'
                              : 'Tous les membres de cet espace font déjà partie de cette cotisation.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.texteSecondaire),
                        ),
                      )
                    : ListView.builder(
                        itemCount: disponibles.length,
                        itemBuilder: (context, i) {
                          final m = disponibles[i];
                          final coche = _selectionnes.contains(m.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: coche,
                            title: Text(m.nomComplet),
                            onChanged: (v) => setState(() {
                              if (v == true) {
                                _selectionnes.add(m.id);
                              } else {
                                _selectionnes.remove(m.id);
                              }
                            }),
                          );
                        },
                      ),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 8),
            Text(_erreur!, style: const TextStyle(color: AppColors.terre)),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: (_enCours || _selectionnes.isEmpty) ? null : _valider,
            child: _enCours
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Text(_selectionnes.isEmpty
                    ? 'AJOUTER'
                    : 'AJOUTER (${_selectionnes.length})'),
          ),
        ],
      ),
    );
  }
}

class _LignePaiement extends ConsumerWidget {
  final String nomMembre;
  final PaiementCotisation paiement;

  const _LignePaiement({required this.nomMembre, required this.paiement});

  Color get _couleurStatut => switch (paiement.statut) {
        StatutPaiement.paye => AppColors.palme,
        StatutPaiement.exonere => AppColors.texteSecondaire,
        StatutPaiement.partiel => AppColors.or,
        StatutPaiement.enRetard => AppColors.terre,
        StatutPaiement.impaye => AppColors.terre,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        title: Text(nomMembre),
        subtitle: Text(
            '${formatMontant(paiement.montantPaye)} / ${formatMontant(paiement.montantDu)}'),
        trailing: RoleGate(
          peutAcceder: (r) => r.peutGererMembres,
          remplacement: Chip(
            label: Text(paiement.statut.libelle),
            backgroundColor: _couleurStatut.withValues(alpha: .15),
            labelStyle: TextStyle(color: _couleurStatut, fontSize: 12),
            visualDensity: VisualDensity.compact,
          ),
          child: TextButton(
            onPressed: paiement.statut == StatutPaiement.paye
                ? null
                : () => _ouvrirAjoutTranche(context, ref),
            child: Text(paiement.statut.libelle),
          ),
        ),
      ),
    );
  }

  void _ouvrirAjoutTranche(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _FormulaireTranche(nomMembre: nomMembre, paiement: paiement),
    );
  }
}

class _FormulaireTranche extends ConsumerStatefulWidget {
  final String nomMembre;
  final PaiementCotisation paiement;

  const _FormulaireTranche({required this.nomMembre, required this.paiement});

  @override
  ConsumerState<_FormulaireTranche> createState() => _FormulaireTrancheState();
}

class _FormulaireTrancheState extends ConsumerState<_FormulaireTranche> {
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
            paiementCotisationId: widget.paiement.id,
            date: DateTime.now(),
            montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
            responsable: responsable,
            modePaiement: _mode,
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
    final restant = widget.paiement.montantDu - widget.paiement.montantPaye;
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
            Text(widget.nomMembre,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
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
