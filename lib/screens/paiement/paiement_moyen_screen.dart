import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import 'paiement_recu_screen.dart';

/// Saisie du montant et du moyen de paiement pour un versement de
/// cotisation — d'après la maquette « Paiement · {membre} » du canvas de
/// design : carte montant sombre texturée, grille de moyens de paiement,
/// sélecteur d'opérateur Mobile Money, référence de transaction.
class PaiementMoyenScreen extends ConsumerStatefulWidget {
  final String paiementCotisationId;
  final String membreNom;
  final String cotisationNom;
  final double montantRestant;

  const PaiementMoyenScreen({
    super.key,
    required this.paiementCotisationId,
    required this.membreNom,
    required this.cotisationNom,
    required this.montantRestant,
  });

  @override
  ConsumerState<PaiementMoyenScreen> createState() =>
      _PaiementMoyenScreenState();
}

class _PaiementMoyenScreenState extends ConsumerState<PaiementMoyenScreen> {
  late final TextEditingController _montantCtrl;
  final _referenceCtrl = TextEditingController();
  ModePaiement _mode = ModePaiement.especes;
  OperateurMobileMoney _operateur = OperateurMobileMoney.orangeMoney;
  bool _enCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _montantCtrl = TextEditingController(
        text: widget.montantRestant.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  void _fixerMontant(double v) {
    setState(() => _montantCtrl.text = v.toStringAsFixed(0));
  }

  Future<void> _valider() async {
    final montant = double.tryParse(_montantCtrl.text.replaceAll(',', '.'));
    if (montant == null || montant <= 0) {
      setState(() => _erreur = 'Montant invalide');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final espace = ref.read(currentEspaceProvider)?.espace;
      final responsable = ref.read(currentUserProvider)?.email ?? '';
      final maintenant = DateTime.now();
      final reference = _referenceCtrl.text.trim();

      await ref.read(tranchesServiceProvider).creer(Tranche(
            id: '',
            paiementCotisationId: widget.paiementCotisationId,
            date: maintenant,
            montant: montant,
            responsable: responsable,
            modePaiement: _mode,
            operateur: _mode == ModePaiement.mobileMoney ? _operateur : null,
            reference: reference.isEmpty ? null : reference,
          ));
      ref.invalidate(paiementsEspaceProvider);

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaiementRecuScreen(
            espaceNom: espace?.nom ?? 'Trésora',
            membreNom: widget.membreNom,
            affectation: widget.cotisationNom,
            montant: montant,
            modePaiement: _mode,
            operateur: _mode == ModePaiement.mobileMoney ? _operateur : null,
            reference: reference.isEmpty ? null : reference,
            encaissePar: responsable,
            date: maintenant,
          ),
        ),
      );
    } catch (e) {
      setState(() => _erreur = "Enregistrement impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Paiement · ${widget.membreNom}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CarteMontant(
            controller: _montantCtrl,
            onMoitie: () => _fixerMontant(widget.montantRestant / 2),
            onSolde: () => _fixerMontant(widget.montantRestant),
          ),
          const SizedBox(height: 20),
          Text('Moyen', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in ModePaiement.values)
                _CarteMoyen(
                  libelle: m.libelle,
                  icone: _iconePourMode(m),
                  actif: _mode == m,
                  onTap: () => setState(() => _mode = m),
                ),
            ],
          ),
          if (_mode == ModePaiement.mobileMoney) ...[
            const SizedBox(height: 20),
            Text('Opérateur', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final o in OperateurMobileMoney.values) ...[
                  Expanded(
                    child: _CarteOperateur(
                      operateur: o,
                      actif: _operateur == o,
                      onTap: () => setState(() => _operateur = o),
                    ),
                  ),
                  if (o != OperateurMobileMoney.values.last)
                    const SizedBox(width: 7),
                ],
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text('Référence de transaction (optionnel)',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.texteSecondaire)),
          const SizedBox(height: 6),
          TextField(
            controller: _referenceCtrl,
            decoration: const InputDecoration(hintText: 'Ex. OM-2608-77412'),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 12),
            Text(_erreur!, style: const TextStyle(color: AppColors.terre)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _enCours ? null : _valider,
            child: _enCours
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text("VALIDER L'ENCAISSEMENT"),
          ),
        ],
      ),
    );
  }
}

IconData _iconePourMode(ModePaiement mode) => switch (mode) {
      ModePaiement.especes => Icons.payments_outlined,
      ModePaiement.mobileMoney => Icons.phone_iphone,
      ModePaiement.virement => Icons.account_balance_outlined,
      ModePaiement.cheque => Icons.receipt_long_outlined,
    };

class _CarteMontant extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onMoitie;
  final VoidCallback onSolde;

  const _CarteMontant(
      {required this.controller, required this.onMoitie, required this.onSolde});

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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PuceMontant(libelle: 'Moitié', onTap: onMoitie),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _PuceMontant(
                    libelle: 'Solde', accent: true, onTap: onSolde),
              ),
            ],
          ),
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

class _CarteMoyen extends StatelessWidget {
  final String libelle;
  final IconData icone;
  final bool actif;
  final VoidCallback onTap;

  const _CarteMoyen({
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

class _CarteOperateur extends StatelessWidget {
  final OperateurMobileMoney operateur;
  final bool actif;
  final VoidCallback onTap;

  const _CarteOperateur(
      {required this.operateur, required this.actif, required this.onTap});

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
