import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart' show ModePaiement;
import '../../models/module_espace.dart';
import '../../models/tresorerie.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/erreurs.dart';

enum _TypeEcriture { recette, depense }

List<CategorieRecette> _categoriesDisponibles(bool eglise) => eglise
    ? const [
        CategorieRecette.dime,
        CategorieRecette.offrandeOrdinaire,
        CategorieRecette.offrandeSpeciale,
        CategorieRecette.offrandeCulteSoir,
        CategorieRecette.don,
        CategorieRecette.autre,
      ]
    : const [
        CategorieRecette.cotisation,
        CategorieRecette.don,
        CategorieRecette.activite,
        CategorieRecette.autre,
      ];

class TresorerieFormScreen extends ConsumerStatefulWidget {
  const TresorerieFormScreen({super.key});

  @override
  ConsumerState<TresorerieFormScreen> createState() =>
      _TresorerieFormScreenState();
}

class _TresorerieFormScreenState extends ConsumerState<TresorerieFormScreen> {
  final _formKey = GlobalKey<FormState>();
  _TypeEcriture _type = _TypeEcriture.recette;
  CategorieRecette? _categorieRecette;
  final _libelleCtrl = TextEditingController();
  final _commentaireCtrl = TextEditingController();
  final _beneficiaireCtrl = TextEditingController();
  final _categorieDepenseCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  ModePaiement _modePaiement = ModePaiement.especes;
  bool _justificatif = false;
  DateTime _date = DateTime.now();
  bool _enCours = false;
  String? _erreur;

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    final espaceId = ref.read(currentEspaceIdProvider);
    if (espaceId == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final montant = double.parse(_montantCtrl.text.replaceAll(',', '.'));
      final responsable = ref.read(currentUserProvider)?.email ?? '';
      if (_type == _TypeEcriture.recette) {
        await ref.read(recettesServiceProvider).creer(Recette(
              id: '',
              espaceId: espaceId,
              date: _date,
              montant: montant,
              categorie: _categorieRecette!,
              libelle: _libelleCtrl.text.trim(),
              responsable: responsable,
              commentaire: _commentaireCtrl.text.trim().isEmpty
                  ? null
                  : _commentaireCtrl.text.trim(),
            ));
      } else {
        await ref.read(depensesServiceProvider).creer(Depense(
              id: '',
              espaceId: espaceId,
              date: _date,
              montant: montant,
              categorie: _categorieDepenseCtrl.text.trim(),
              description: _libelleCtrl.text.trim(),
              beneficiaire: _beneficiaireCtrl.text.trim(),
              modePaiement: _modePaiement,
              responsable: responsable,
              justificatif: _justificatif,
            ));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Enregistrement impossible : ${messageErreur(e)}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final espace = ref.watch(currentEspaceProvider)?.espace;
    final eglise = espace == null ||
        espace.aModule(ModuleEspace.dimes) ||
        espace.aModule(ModuleEspace.offrandes);
    final categories = _categoriesDisponibles(eglise);
    if (_categorieRecette == null || !categories.contains(_categorieRecette)) {
      _categorieRecette = categories.first;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle écriture')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<_TypeEcriture>(
                  segments: const [
                    ButtonSegment(
                        value: _TypeEcriture.recette,
                        label: Text('Recette'),
                        icon: Icon(Icons.add)),
                    ButtonSegment(
                        value: _TypeEcriture.depense,
                        label: Text('Dépense'),
                        icon: Icon(Icons.remove)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 16),
                if (_type == _TypeEcriture.recette)
                  DropdownButtonFormField<CategorieRecette>(
                    initialValue: _categorieRecette,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Catégorie'),
                    items: categories
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.libelle)))
                        .toList(),
                    onChanged: (v) => setState(() => _categorieRecette = v!),
                  ),
                if (_type == _TypeEcriture.depense) ...[
                  TextFormField(
                    controller: _categorieDepenseCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      hintText:
                          'Entretien bâtiment, Transport, Communication…',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requis' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _beneficiaireCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Bénéficiaire'),
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _libelleCtrl,
                  decoration: InputDecoration(
                    labelText: _type == _TypeEcriture.recette
                        ? 'Libellé'
                        : 'Description',
                  ),
                ),
                if (_type == _TypeEcriture.recette) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _commentaireCtrl,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Commentaire (optionnel)'),
                  ),
                ],
                if (_type == _TypeEcriture.depense) ...[
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ModePaiement>(
                    initialValue: _modePaiement,
                    decoration:
                        const InputDecoration(labelText: 'Mode de paiement'),
                    items: ModePaiement.values
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text(m.libelle)))
                        .toList(),
                    onChanged: (v) => setState(() => _modePaiement = v!),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Justificatif'),
                    subtitle: const Text('Reçu joint pour cette dépense'),
                    value: _justificatif,
                    onChanged: (v) => setState(() => _justificatif = v),
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _montantCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Montant (FCFA)'),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return (n == null || n <= 0) ? 'Montant invalide' : null;
                  },
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(formatDate(_date)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final choisie = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (choisie != null) setState(() => _date = choisie);
                  },
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(_erreur!,
                      style: const TextStyle(color: AppColors.terre)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _enCours ? null : _enregistrer,
                  child: _enCours
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('ENREGISTRER'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
