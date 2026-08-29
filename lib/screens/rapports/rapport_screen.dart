import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../models/tresorerie.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

enum _Periode { mois, trimestre, annee, personnalise }

/// Génération de rapport — d'après la maquette « Rapports » du canvas de
/// design : chips de période, carte de prévisualisation sombre avec
/// répartition par catégorie de recette, action de partage. Seul le PDF
/// est un format réel (RapportService) — pas de boutons Excel/Word
/// factices comme sur la maquette, cette app ne génère que du PDF.
class RapportScreen extends ConsumerStatefulWidget {
  const RapportScreen({super.key});

  @override
  ConsumerState<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends ConsumerState<RapportScreen> {
  late DateTime _debut = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fin = DateTime.now();
  _Periode _periode = _Periode.mois;
  bool _enCours = false;
  String? _erreur;

  void _choisirPeriode(_Periode p) {
    final maintenant = DateTime.now();
    setState(() {
      _periode = p;
      switch (p) {
        case _Periode.mois:
          _debut = DateTime(maintenant.year, maintenant.month, 1);
          _fin = maintenant;
        case _Periode.trimestre:
          _debut = DateTime(maintenant.year, maintenant.month - 2, 1);
          _fin = maintenant;
        case _Periode.annee:
          _debut = DateTime(maintenant.year, 1, 1);
          _fin = maintenant;
        case _Periode.personnalise:
          break;
      }
    });
  }

  Future<void> _choisirDebut() async {
    final choisie = await showDatePicker(
      context: context,
      initialDate: _debut,
      firstDate: DateTime(2000),
      lastDate: _fin,
    );
    if (choisie != null) {
      setState(() {
        _debut = choisie;
        _periode = _Periode.personnalise;
      });
    }
  }

  Future<void> _choisirFin() async {
    final choisie = await showDatePicker(
      context: context,
      initialDate: _fin,
      firstDate: _debut,
      lastDate: DateTime.now(),
    );
    if (choisie != null) {
      setState(() {
        _fin = choisie;
        _periode = _Periode.personnalise;
      });
    }
  }

  Future<void> _partager() async {
    final espace = ref.read(currentEspaceProvider)?.espace;
    if (espace == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final finInclusive =
          DateTime(_fin.year, _fin.month, _fin.day, 23, 59, 59);
      final recettes = (ref.read(recettesStreamProvider).valueOrNull ?? [])
          .where(
              (r) => !r.date.isBefore(_debut) && !r.date.isAfter(finInclusive))
          .toList();
      final depenses = (ref.read(depensesStreamProvider).valueOrNull ?? [])
          .where(
              (d) => !d.date.isBefore(_debut) && !d.date.isAfter(finInclusive))
          .toList();
      final pdfBytes =
          await ref.read(rapportServiceProvider).genererRapportTresorerie(
                espace: espace,
                debut: _debut,
                fin: _fin,
                recettes: recettes,
                depenses: depenses,
              );
      await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'rapport-${espace.nom}-${formatDate(_fin)}.pdf');
    } catch (e) {
      setState(() => _erreur = "Génération impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final espace = ref.watch(currentEspaceProvider)?.espace;
    final recettes = ref.watch(recettesStreamProvider).valueOrNull ?? [];
    final depenses = ref.watch(depensesStreamProvider).valueOrNull ?? [];
    final finInclusive = DateTime(_fin.year, _fin.month, _fin.day, 23, 59, 59);
    final recettesPeriode = recettes
        .where((r) => !r.date.isBefore(_debut) && !r.date.isAfter(finInclusive))
        .toList();
    final depensesPeriode = depenses
        .where((d) => !d.date.isBefore(_debut) && !d.date.isAfter(finInclusive))
        .toList();
    final totalRecettes =
        recettesPeriode.fold(0.0, (a, r) => a + r.montant);
    final totalDepenses =
        depensesPeriode.fold(0.0, (a, d) => a + d.montant);

    final parCategorie = <CategorieRecette, double>{};
    for (final r in recettesPeriode) {
      parCategorie[r.categorie] = (parCategorie[r.categorie] ?? 0) + r.montant;
    }
    final categoriesTriees = parCategorie.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Rapports')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 6,
              children: [
                _PucePeriode(
                    libelle: 'Mois',
                    actif: _periode == _Periode.mois,
                    onTap: () => _choisirPeriode(_Periode.mois)),
                _PucePeriode(
                    libelle: 'Trimestre',
                    actif: _periode == _Periode.trimestre,
                    onTap: () => _choisirPeriode(_Periode.trimestre)),
                _PucePeriode(
                    libelle: 'Année',
                    actif: _periode == _Periode.annee,
                    onTap: () => _choisirPeriode(_Periode.annee)),
                _PucePeriode(
                    libelle: 'Perso.',
                    actif: _periode == _Periode.personnalise,
                    onTap: () => _choisirPeriode(_Periode.personnalise)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Du'),
                    subtitle: Text(formatDate(_debut)),
                    trailing: const Icon(Icons.calendar_today, size: 16),
                    onTap: _choisirDebut,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Au'),
                    subtitle: Text(formatDate(_fin)),
                    trailing: const Icon(Icons.calendar_today, size: 16),
                    onTap: _choisirFin,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.bordure),
                color: AppColors.carte,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.graphite,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRÉSORA · ${(espace?.nom ?? '').toUpperCase()}',
                            style: AppFonts.eyebrow(
                                color: Colors.white.withValues(alpha: .55))),
                        const SizedBox(height: 5),
                        Text('Rapport financier',
                            style: AppFonts.heading(
                                fontSize: 16, color: Colors.white)),
                        Text(
                            '${formatDate(_debut)} – ${formatDate(_fin)}',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: .55))),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _MiniStatRapport(
                                  libelle: 'Solde net',
                                  montant: totalRecettes - totalDepenses),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStatRapport(
                                  libelle: 'Recettes',
                                  montant: totalRecettes,
                                  couleur: AppColors.palme),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniStatRapport(
                                  libelle: 'Dépenses',
                                  montant: totalDepenses,
                                  couleur: AppColors.terre),
                            ),
                          ],
                        ),
                        if (categoriesTriees.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          for (final entry in categoriesTriees.take(5)) ...[
                            _BarreCategorie(
                              libelle: entry.key.libelle,
                              part: totalRecettes == 0
                                  ? 0
                                  : entry.value / totalRecettes,
                            ),
                            const SizedBox(height: 7),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_erreur != null) ...[
              Text(_erreur!, style: const TextStyle(color: AppColors.terre)),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _enCours ? null : _partager,
              icon: _enCours
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('GÉNÉRER ET PARTAGER LE PDF'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PucePeriode extends StatelessWidget {
  final String libelle;
  final bool actif;
  final VoidCallback onTap;

  const _PucePeriode(
      {required this.libelle, required this.actif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: actif ? AppColors.graphite : AppColors.carte,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: actif ? AppColors.graphite : AppColors.bordure),
          ),
          child: Text(libelle,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: actif ? FontWeight.w800 : FontWeight.w600,
                  color: actif ? Colors.white : AppColors.texteSecondaire)),
        ),
      ),
    );
  }
}

class _MiniStatRapport extends StatelessWidget {
  final String libelle;
  final double montant;
  final Color couleur;

  const _MiniStatRapport(
      {required this.libelle,
      required this.montant,
      this.couleur = AppColors.texteEncre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.bordure),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(libelle,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.texteSecondaire)),
          const SizedBox(height: 2),
          Text(formatMontant(montant),
              style: AppFonts.montant(fontSize: 12, color: couleur)),
        ],
      ),
    );
  }
}

class _BarreCategorie extends StatelessWidget {
  final String libelle;
  final double part;

  const _BarreCategorie({required this.libelle, required this.part});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 76,
          child: Text(libelle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.texteSecondaire)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: part.clamp(0, 1),
              minHeight: 14,
              backgroundColor: AppColors.fond,
              color: AppColors.terre,
            ),
          ),
        ),
      ],
    );
  }
}
