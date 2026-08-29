import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart';
import '../../models/membre.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import 'paiement_moyen_screen.dart';

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
///
/// Habillage d'après la maquette « Encaisser » du canvas de design ; le
/// bouton « Verser » ouvre maintenant le vrai flux à 3 écrans (montant +
/// moyen de paiement → reçu) au lieu d'un formulaire en feuille modale.
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
      appBar: AppBar(title: const Text('Encaisser')),
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
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: aDes ? () => setState(() => _ouvert = !_ouvert) : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.graphite,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaiementMoyenScreen(
          paiementCotisationId: d.paiement.id,
          membreNom: membre.nomComplet,
          cotisationNom: d.cotisation.nom,
          montantRestant: d.restant,
        ),
      ),
    );
  }
}
