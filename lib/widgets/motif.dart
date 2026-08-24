import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Motifs de tissage — la signature visuelle de Trésora, portée depuis
/// tresora-app (src/components/brand/motif.tsx). Géométrie inspirée des
/// bandes de coton tissées ouest-africaines : segments de largeurs inégales,
/// comme les duites d'un pagne. Volontairement abstraite : aucun symbole
/// adinkra n'est repris, ceux-ci portant des significations précises qu'il
/// serait négligent d'employer en simple décor.
enum Tonalite { or, palme, terre, indigo, mixte }

class _Segment {
  final int flex;
  final Color Function() couleur;
  const _Segment(this.flex, this.couleur);
}

Map<Tonalite, List<_Segment>> _segments() => {
      Tonalite.or: [
        _Segment(7, () => AppColors.or),
        _Segment(2, () => AppColors.indigoProfond),
        _Segment(4, () => AppColors.or),
        _Segment(1, () => AppColors.terre),
        _Segment(3, () => AppColors.or),
        _Segment(2, () => AppColors.indigoProfond),
      ],
      Tonalite.palme: [
        _Segment(5, () => AppColors.palme),
        _Segment(2, () => AppColors.or),
        _Segment(6, () => AppColors.palme),
        _Segment(1, () => AppColors.indigoProfond),
        _Segment(3, () => AppColors.palme),
      ],
      Tonalite.terre: [
        _Segment(4, () => AppColors.terre),
        _Segment(1, () => AppColors.or),
        _Segment(7, () => AppColors.terre),
        _Segment(2, () => AppColors.indigoProfond),
        _Segment(3, () => AppColors.terre),
      ],
      Tonalite.indigo: [
        _Segment(6, () => AppColors.indigoProfond),
        _Segment(2, () => AppColors.or),
        _Segment(4, () => AppColors.indigoProfond),
        _Segment(1, () => AppColors.palme),
        _Segment(5, () => AppColors.indigoProfond),
      ],
      Tonalite.mixte: [
        _Segment(4, () => AppColors.or),
        _Segment(3, () => AppColors.palme),
        _Segment(1, () => AppColors.indigoProfond),
        _Segment(5, () => AppColors.terre),
        _Segment(2, () => AppColors.or),
        _Segment(3, () => AppColors.indigoProfond),
      ],
    };

/// Bande tissée horizontale — remplace le filet uni en tête de carte/écran.
/// Chaque segment a une largeur différente, comme les duites d'un vrai pagne.
class BandeTissee extends StatelessWidget {
  final Tonalite tonalite;
  final double epaisseur;

  const BandeTissee({super.key, this.tonalite = Tonalite.or, this.epaisseur = 3});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(epaisseur),
      child: SizedBox(
        height: epaisseur,
        child: Row(
          children: _segments()[tonalite]!
              .map((s) => Expanded(flex: s.flex, child: ColoredBox(color: s.couleur())))
              .toList(),
        ),
      ),
    );
  }
}

/// Lisière verticale — la même bande, pivotée, pour border un panneau.
class LisiereVerticale extends StatelessWidget {
  final Tonalite tonalite;
  final double epaisseur;

  const LisiereVerticale({super.key, this.tonalite = Tonalite.or, this.epaisseur = 3});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: epaisseur,
      child: Column(
        children: _segments()[tonalite]!
            .map((s) => Expanded(flex: s.flex, child: ColoredBox(color: s.couleur())))
            .toList(),
      ),
    );
  }
}
