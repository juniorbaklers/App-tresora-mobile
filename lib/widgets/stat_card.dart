import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'motif.dart';

class StatCard extends StatelessWidget {
  final String titre;
  final double montant;
  final String sousTitre;
  final Color? couleurFond;
  final Color couleurTexte;
  final Tonalite tonalite;

  const StatCard({
    super.key,
    required this.titre,
    required this.montant,
    required this.sousTitre,
    this.couleurFond,
    this.couleurTexte = AppColors.texteEncre,
    this.tonalite = Tonalite.or,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleurFond ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: couleurFond == null ? Border.all(color: AppColors.bordure) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BandeTissee(tonalite: tonalite),
          const SizedBox(height: 10),
          Text(
            titre,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
              color: couleurTexte.withValues(alpha: .75),
            ),
          ),
          const SizedBox(height: 8),
          Text(formatMontant(montant), style: AppFonts.montant(fontSize: 20, color: couleurTexte)),
          const SizedBox(height: 4),
          Text(sousTitre, style: TextStyle(fontSize: 12, color: couleurTexte.withValues(alpha: .7))),
        ],
      ),
    );
  }
}
