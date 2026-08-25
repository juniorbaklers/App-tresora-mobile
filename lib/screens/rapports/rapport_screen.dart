import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

class RapportScreen extends ConsumerStatefulWidget {
  const RapportScreen({super.key});

  @override
  ConsumerState<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends ConsumerState<RapportScreen> {
  late DateTime _debut = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _fin = DateTime.now();
  bool _enCours = false;
  String? _erreur;

  Future<void> _choisirDebut() async {
    final choisie = await showDatePicker(
      context: context,
      initialDate: _debut,
      firstDate: DateTime(2000),
      lastDate: _fin,
    );
    if (choisie != null) setState(() => _debut = choisie);
  }

  Future<void> _choisirFin() async {
    final choisie = await showDatePicker(
      context: context,
      initialDate: _fin,
      firstDate: _debut,
      lastDate: DateTime.now(),
    );
    if (choisie != null) setState(() => _fin = choisie);
  }

  Future<void> _partager() async {
    final espace = ref.read(currentEspaceProvider)?.espace;
    if (espace == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final finInclusive = DateTime(_fin.year, _fin.month, _fin.day, 23, 59, 59);
      final recettes = (ref.read(recettesStreamProvider).valueOrNull ?? [])
          .where((r) => !r.date.isBefore(_debut) && !r.date.isAfter(finInclusive))
          .toList();
      final depenses = (ref.read(depensesStreamProvider).valueOrNull ?? [])
          .where((d) => !d.date.isBefore(_debut) && !d.date.isAfter(finInclusive))
          .toList();
      final pdfBytes = await ref.read(rapportServiceProvider).genererRapportTresorerie(
            espace: espace,
            debut: _debut,
            fin: _fin,
            recettes: recettes,
            depenses: depenses,
          );
      await Printing.sharePdf(bytes: pdfBytes, filename: 'rapport-${espace.nom}-${formatDate(_fin)}.pdf');
    } catch (e) {
      setState(() => _erreur = "Génération impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recettes = ref.watch(recettesStreamProvider).valueOrNull ?? [];
    final depenses = ref.watch(depensesStreamProvider).valueOrNull ?? [];
    final finInclusive = DateTime(_fin.year, _fin.month, _fin.day, 23, 59, 59);
    final totalRecettes = recettes
        .where((r) => !r.date.isBefore(_debut) && !r.date.isAfter(finInclusive))
        .fold(0.0, (a, r) => a + r.montant);
    final totalDepenses = depenses
        .where((d) => !d.date.isBefore(_debut) && !d.date.isAfter(finInclusive))
        .fold(0.0, (a, d) => a + d.montant);

    return Scaffold(
      appBar: AppBar(title: const Text('Rapport de trésorerie')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Du'),
                      subtitle: Text(formatDate(_debut)),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      onTap: _choisirDebut,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Au'),
                      subtitle: Text(formatDate(_fin)),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      onTap: _choisirFin,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Resume(titre: 'Recettes', montant: totalRecettes, couleur: AppColors.palme),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Resume(titre: 'Dépenses', montant: totalDepenses, couleur: AppColors.terre),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Resume(titre: 'Solde net', montant: totalRecettes - totalDepenses),
              const Spacer(),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('GÉNÉRER ET PARTAGER LE PDF'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ],
          ),
        ),
      ),
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
