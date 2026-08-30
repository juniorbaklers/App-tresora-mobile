import 'package:flutter/material.dart';
import '../models/cotisation.dart';
import '../theme/app_theme.dart';

/// Widgets de saisie d'un moyen de paiement — carte montant sombre, grille
/// de moyens, sélecteur d'opérateur Mobile Money. Extraits de
/// `paiement_moyen_screen.dart` (flux « Encaisser ») pour être réutilisés
/// par tout autre flux d'encaissement de l'app (ex. contribution à un
/// événement) sans dupliquer ce bloc de présentation.

IconData iconePourModePaiement(ModePaiement mode) => switch (mode) {
      ModePaiement.especes => Icons.payments_outlined,
      ModePaiement.mobileMoney => Icons.phone_iphone,
      ModePaiement.virement => Icons.account_balance_outlined,
      ModePaiement.cheque => Icons.receipt_long_outlined,
    };

class CarteMontantSaisie extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onMoitie;
  final VoidCallback? onSolde;
  final String libelleSolde;

  const CarteMontantSaisie({
    super.key,
    required this.controller,
    this.onMoitie,
    this.onSolde,
    this.libelleSolde = 'Solde',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text('MONTANT',
              style: AppFonts.eyebrow(color: Colors.white.withValues(alpha: .55))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: AppFonts.montant(fontSize: 34, color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
          ),
          if (onMoitie != null && onSolde != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _PuceMontant(libelle: 'Moitié', onTap: onMoitie!),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _PuceMontant(
                      libelle: libelleSolde, accent: true, onTap: onSolde!),
                ),
              ],
            ),
          ] else if (onSolde != null) ...[
            const SizedBox(height: 12),
            _PuceMontant(libelle: libelleSolde, accent: true, onTap: onSolde!),
          ],
        ],
      ),
    );
  }
}

class _PuceMontant extends StatelessWidget {
  final String libelle;
  final bool accent;
  final VoidCallback onTap;

  const _PuceMontant(
      {required this.libelle, this.accent = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent ? AppColors.or : Colors.white.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(libelle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent ? AppColors.graphite : Colors.white)),
        ),
      ),
    );
  }
}

class CarteMoyenPaiement extends StatelessWidget {
  final String libelle;
  final IconData icone;
  final bool actif;
  final VoidCallback onTap;

  const CarteMoyenPaiement({
    super.key,
    required this.libelle,
    required this.icone,
    required this.actif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final largeur = (MediaQuery.of(context).size.width - 16 * 2 - 8) / 2;
    return Material(
      color: actif ? AppColors.terre.withValues(alpha: .08) : AppColors.carte,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: largeur,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: actif ? AppColors.terre : AppColors.bordure,
                width: actif ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icone,
                  size: 22,
                  color: actif ? AppColors.terre : AppColors.texteSecondaire),
              const SizedBox(height: 6),
              Text(libelle,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          actif ? AppColors.terre : AppColors.texteSecondaire)),
            ],
          ),
        ),
      ),
    );
  }
}

class CarteOperateurMobileMoney extends StatelessWidget {
  final OperateurMobileMoney operateur;
  final bool actif;
  final VoidCallback onTap;

  const CarteOperateurMobileMoney(
      {super.key, required this.operateur, required this.actif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.carte,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: actif ? AppColors.terre : AppColors.bordure,
                width: actif ? 2 : 1),
          ),
          child: Text(
            operateur.libelle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: actif ? AppColors.terre : AppColors.texteSecondaire),
          ),
        ),
      ),
    );
  }
}
