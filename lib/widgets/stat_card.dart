import 'package:flutter/material.dart';
import '../utils/format.dart';

class StatCard extends StatelessWidget {
  final String titre;
  final double montant;
  final String sousTitre;
  final Color? couleurFond;
  final Color couleurTexte;

  const StatCard({
    super.key,
    required this.titre,
    required this.montant,
    required this.sousTitre,
    this.couleurFond,
    this.couleurTexte = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleurFond ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: couleurFond == null ? Border.all(color: const Color(0xFFE7E0CF)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Text(
            formatMontant(montant),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: couleurTexte,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(sousTitre, style: TextStyle(fontSize: 12, color: couleurTexte.withValues(alpha: .7))),
        ],
      ),
    );
  }
}
