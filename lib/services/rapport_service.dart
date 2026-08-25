import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/espace.dart';
import '../models/tresorerie.dart';
import '../utils/format.dart';

/// Génère un rapport de trésorerie (recettes/dépenses) au format PDF pour
/// une période donnée — pas de table dédiée côté base, tout est recalculé
/// à la volée à partir des données déjà chargées (recettesStreamProvider /
/// depensesStreamProvider), filtrées côté client sur la période choisie.
class RapportService {
  Future<Uint8List> genererRapportTresorerie({
    required Espace espace,
    required DateTime debut,
    required DateTime fin,
    required List<Recette> recettes,
    required List<Depense> depenses,
  }) async {
    final doc = pw.Document();

    final totalRecettes = recettes.fold(0.0, (a, r) => a + r.montant);
    final totalDepenses = depenses.fold(0.0, (a, d) => a + d.montant);
    final soldeNet = totalRecettes - totalDepenses;

    final recettesParCategorie = <CategorieRecette, double>{};
    for (final r in recettes) {
      recettesParCategorie[r.categorie] =
          (recettesParCategorie[r.categorie] ?? 0) + r.montant;
    }
    final depensesParCategorie = <String, double>{};
    for (final d in depenses) {
      final cle = d.categorie.isEmpty ? 'Autre' : d.categorie;
      depensesParCategorie[cle] = (depensesParCategorie[cle] ?? 0) + d.montant;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(espace.nom,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Rapport de trésorerie',
                style:
                    const pw.TextStyle(fontSize: 13, color: PdfColors.grey700)),
            pw.Text(
              'Période du ${formatDate(debut)} au ${formatDate(fin)} — généré le ${formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 16),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _bloc('Total recettes', totalRecettes, PdfColors.green800),
              _bloc('Total dépenses', totalDepenses, PdfColors.red800),
              _bloc('Solde net', soldeNet,
                  soldeNet >= 0 ? PdfColors.green800 : PdfColors.red800),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Text('Recettes par catégorie',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _tableau(
            recettesParCategorie.entries
                .map((e) => MapEntry(e.key.libelle, e.value))
                .toList()
              ..sort((a, b) => b.value.compareTo(a.value)),
            totalRecettes,
          ),
          pw.SizedBox(height: 24),
          pw.Text('Dépenses par catégorie',
              style:
                  pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          _tableau(
            depensesParCategorie.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)),
            totalDepenses,
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _bloc(String titre, double montant, PdfColor couleur) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(titre.toUpperCase(),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(formatMontant(montant),
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: couleur)),
      ],
    );
  }

  pw.Widget _tableau(List<MapEntry<String, double>> lignes, double total) {
    if (lignes.isEmpty) {
      return pw.Text('Aucune écriture sur cette période',
          style: const pw.TextStyle(color: PdfColors.grey600));
    }
    return pw.TableHelper.fromTextArray(
      headers: const ['Catégorie', 'Montant'],
      data: [
        for (final l in lignes) [l.key, formatMontant(l.value)],
        ['TOTAL', formatMontant(total)],
      ],
      cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellStyle: const pw.TextStyle(fontSize: 10),
      headerStyle: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }
}
