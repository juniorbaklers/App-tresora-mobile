import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../models/cotisation.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// Confirmation d'un encaissement — d'après la maquette « Paiement
/// enregistré » du canvas de design : coche, carte reçu (montant + détail),
/// partager (vrai PDF via RecuService) ou repartir sur un nouvel
/// encaissement. Contrairement à la maquette, pas de bandeau "enregistré
/// hors ligne, sera synchronisé" : le mode hors-ligne de cette app est en
/// lecture seule (voir cache_hors_ligne.dart), il n'y a pas de file
/// d'écriture différée à annoncer.
class PaiementRecuScreen extends ConsumerStatefulWidget {
  final String espaceNom;
  final String membreNom;
  final String labelContributeur;
  final String affectation;
  final double montant;
  final ModePaiement modePaiement;
  final OperateurMobileMoney? operateur;
  final String? reference;
  final String encaissePar;
  final DateTime date;

  const PaiementRecuScreen({
    super.key,
    required this.espaceNom,
    required this.membreNom,
    this.labelContributeur = 'Membre',
    required this.affectation,
    required this.montant,
    required this.modePaiement,
    this.operateur,
    this.reference,
    required this.encaissePar,
    required this.date,
  });

  @override
  ConsumerState<PaiementRecuScreen> createState() =>
      _PaiementRecuScreenState();
}

class _PaiementRecuScreenState extends ConsumerState<PaiementRecuScreen> {
  bool _partageEnCours = false;

  Future<void> _partager() async {
    setState(() => _partageEnCours = true);
    try {
      final bytes = await ref.read(recuServiceProvider).genererRecu(
            espaceNom: widget.espaceNom,
            membreNom: widget.membreNom,
            labelContributeur: widget.labelContributeur,
            affectation: widget.affectation,
            montant: widget.montant,
            modePaiement: widget.modePaiement,
            operateur: widget.operateur,
            reference: widget.reference,
            encaissePar: widget.encaissePar,
            date: widget.date,
          );
      await Printing.sharePdf(
          bytes: bytes, filename: 'recu-${formatDate(widget.date)}.pdf');
    } finally {
      if (mounted) setState(() => _partageEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 74,
                height: 74,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.or.withValues(alpha: .15),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.or,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: AppColors.graphite),
                ),
              ),
              const SizedBox(height: 18),
              Text('Paiement enregistré',
                  style:
                      AppFonts.heading(fontSize: 20, color: AppColors.texteEncre)),
              const SizedBox(height: 5),
              Text('Versement enregistré pour ${widget.membreNom}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.texteSecondaire)),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.carte,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.bordure),
                ),
                child: Column(
                  children: [
                    Text(formatMontant(widget.montant),
                        style: AppFonts.montant(
                            fontSize: 26, color: AppColors.texteEncre)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    _LigneRecu(
                        libelle: widget.labelContributeur,
                        valeur: widget.membreNom),
                    _LigneRecu(
                        libelle: 'Affectation', valeur: widget.affectation),
                    _LigneRecu(
                        libelle: 'Moyen', valeur: widget.modePaiement.libelle),
                    if (widget.operateur != null)
                      _LigneRecu(
                          libelle: 'Opérateur',
                          valeur: widget.operateur!.libelle),
                    if (widget.reference != null)
                      _LigneRecu(
                          libelle: 'Référence', valeur: widget.reference!),
                    _LigneRecu(
                        libelle: 'Encaissé par',
                        valeur:
                            '${widget.encaissePar} · ${widget.date.hour.toString().padLeft(2, '0')}:${widget.date.minute.toString().padLeft(2, '0')}'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _partageEnCours ? null : _partager,
                  icon: _partageEnCours
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.ios_share),
                  label: const Text('Partager le reçu'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Nouvel encaissement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LigneRecu extends StatelessWidget {
  final String libelle;
  final String valeur;

  const _LigneRecu({required this.libelle, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(libelle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.texteSecondaire)),
          Text(valeur,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texteEncre)),
        ],
      ),
    );
  }
}
