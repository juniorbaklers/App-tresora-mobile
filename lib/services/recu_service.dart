import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/cotisation.dart';
import '../utils/format.dart';

/// Génère un reçu d'encaissement au format PDF pour un versement de
/// cotisation — même pattern que `RapportService`, un seul document simple,
/// pas de table dédiée côté base.
class RecuService {
  Future<Uint8List> genererRecu({
    required String espaceNom,
    required String membreNom,
    required String affectation,
    required double montant,
    required ModePaiement modePaiement,
    OperateurMobileMoney? operateur,
    String? reference,
    required String encaissePar,
    required DateTime date,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(espaceNom,
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Reçu d\'encaissement',
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 20),
            pw.Center(
              child: pw.Text(formatMontant(montant),
                  style: pw.TextStyle(
                      fontSize: 28, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            _ligne('Membre', membreNom),
            _ligne('Affectation', affectation),
            _ligne('Moyen', modePaiement.libelle),
            if (operateur != null) _ligne('Opérateur', operateur.libelle),
            if (reference != null && reference.isNotEmpty)
              _ligne('Référence', reference),
            _ligne('Encaissé par', encaissePar),
            _ligne('Date', '${formatDate(date)} à '
                '${date.hour.toString().padLeft(2, '0')}:'
                '${date.minute.toString().padLeft(2, '0')}'),
            pw.Divider(),
          ],
        ),
      ),
    );

    return doc.save();
  }

  pw.Widget _ligne(String libelle, String valeur) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(libelle, style: const pw.TextStyle(color: PdfColors.grey700)),
            pw.Text(valeur,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
}
