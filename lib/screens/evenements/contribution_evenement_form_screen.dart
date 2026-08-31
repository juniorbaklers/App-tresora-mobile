import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart';
import '../../models/evenement.dart';
import '../../models/membre.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/saisie_paiement.dart';
import '../paiement/paiement_recu_screen.dart';
import '../../utils/erreurs.dart';

/// Enregistrement d'une contribution à un événement (collecte ponctuelle) —
/// même flux riche que l'encaissement d'une cotisation (grille de moyens de
/// paiement, opérateur Mobile Money, référence, reçu PDF partageable), à la
/// différence près que le contributeur est saisi en texte libre plutôt que
/// choisi dans la liste des membres : une collecte accueille aussi des
/// donateurs qui n'ont jamais été enregistrés comme membres.
class ContributionEvenementFormScreen extends ConsumerStatefulWidget {
  final Evenement evenement;

  const ContributionEvenementFormScreen({super.key, required this.evenement});

  @override
  ConsumerState<ContributionEvenementFormScreen> createState() =>
      _ContributionEvenementFormScreenState();
}

class _ContributionEvenementFormScreenState
    extends ConsumerState<ContributionEvenementFormScreen> {
  final _nomCtrl = TextEditingController();
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
        text: widget.evenement.montantSuggere?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _montantCtrl.dispose();
    _referenceCtrl.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final nom = _nomCtrl.text.trim();
    if (nom.isEmpty) {
      setState(() => _erreur = 'Nom du contributeur requis');
      return;
    }
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

      await ref.read(contributionsEvenementServiceProvider).creer(
            ContributionEvenement(
              id: '',
              evenementId: widget.evenement.id,
              nomContributeur: nom,
              montant: montant,
              modePaiement: _mode,
              operateur: _mode == ModePaiement.mobileMoney ? _operateur : null,
              reference: reference.isEmpty ? null : reference,
              responsable: responsable,
              date: maintenant,
            ),
          );

      if (mounted) await _proposerAjoutMembre(nom);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaiementRecuScreen(
            espaceNom: espace?.nom ?? 'Trésora',
            membreNom: nom,
            labelContributeur: 'Contributeur',
            affectation: widget.evenement.nom,
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
      setState(() => _erreur = "Enregistrement impossible : ${messageErreur(e)}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  /// Si le contributeur saisi ne correspond à aucun membre existant de
  /// l'espace, propose de l'ajouter au registre des membres — pour qu'un
  /// donateur régulier ne reste pas invisible du suivi des cotisations.
  Future<void> _proposerAjoutMembre(String nom) async {
    final espaceId = widget.evenement.espaceId;
    final membres = ref.read(membresStreamProvider).valueOrNull ?? [];
    final dejaMembre = membres
        .any((m) => m.nomComplet.trim().toLowerCase() == nom.toLowerCase());
    if (dejaMembre) return;

    final ajouter = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter comme membre ?'),
        content: Text(
            "$nom n'est pas encore membre de cet espace. L'ajouter au registre des membres ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non merci'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    if (ajouter != true || !mounted) return;

    final parts = nom.split(RegExp(r'\s+'));
    final prenom = parts.first;
    final nomFamille = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    await ref.read(membresServiceProvider).creer(Membre(
          id: '',
          espaceId: espaceId,
          nom: nomFamille,
          prenom: prenom,
          telephone: '',
          actif: true,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Contribution · ${widget.evenement.nom}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nomCtrl,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(labelText: 'Nom du contributeur'),
          ),
          const SizedBox(height: 16),
          CarteMontantSaisie(
            controller: _montantCtrl,
            libelleSolde: 'Suggéré',
            onSolde: widget.evenement.montantSuggere == null
                ? null
                : () => setState(() => _montantCtrl.text =
                    widget.evenement.montantSuggere!.toStringAsFixed(0)),
          ),
          const SizedBox(height: 20),
          Text('Moyen', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in ModePaiement.values)
                CarteMoyenPaiement(
                  libelle: m.libelle,
                  icone: iconePourModePaiement(m),
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
                    child: CarteOperateurMobileMoney(
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
                : const Text('ENREGISTRER LA CONTRIBUTION'),
          ),
        ],
      ),
    );
  }
}
