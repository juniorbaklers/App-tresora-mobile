import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/mouvement.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// Une seule et même valeur sentinelle pour représenter "Caisse Générale"
/// (caisse_id = null côté base) dans le sélecteur de caisse pour une dépense.
const _caisseGeneraleSentinelle = '__caisse_generale__';

class MouvementFormScreen extends ConsumerStatefulWidget {
  const MouvementFormScreen({super.key});

  @override
  ConsumerState<MouvementFormScreen> createState() => _MouvementFormScreenState();
}

class _MouvementFormScreenState extends ConsumerState<MouvementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  TypeMouvement _type = TypeMouvement.entree;
  String? _caisseId;
  String? _membreId;
  final _nomLibreCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  final _motifCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _nomLibreCtrl.dispose();
    _montantCtrl.dispose();
    _motifCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == TypeMouvement.entree && _caisseId == null) {
      setState(() => _erreur = 'Sélectionne une caisse pour cette entrée.');
      return;
    }
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final caisseId = _type == TypeMouvement.depense && _caisseId == _caisseGeneraleSentinelle
          ? null
          : _caisseId;
      final mouvement = Mouvement(
        id: '',
        type: _type,
        caisseId: caisseId,
        membreId: _membreId,
        nomLibre: _membreId == null && _nomLibreCtrl.text.trim().isNotEmpty ? _nomLibreCtrl.text.trim() : null,
        date: _date,
        montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
        motif: _motifCtrl.text.trim().isEmpty ? null : _motifCtrl.text.trim(),
      );
      await ref.read(mouvementsServiceProvider).creer(mouvement);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Enregistrement impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caissesAsync = ref.watch(caissesStreamProvider);
    final membresAsync = ref.watch(membresStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau mouvement')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<TypeMouvement>(
                  segments: const [
                    ButtonSegment(value: TypeMouvement.entree, label: Text('Entrée'), icon: Icon(Icons.add)),
                    ButtonSegment(value: TypeMouvement.depense, label: Text('Dépense'), icon: Icon(Icons.remove)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) => setState(() {
                    _type = s.first;
                    _caisseId = null;
                  }),
                ),
                const SizedBox(height: 16),
                caissesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erreur caisses : $e'),
                  data: (caisses) {
                    final items = <DropdownMenuItem<String>>[
                      if (_type == TypeMouvement.depense)
                        const DropdownMenuItem(value: _caisseGeneraleSentinelle, child: Text('Caisse Générale')),
                      ...caisses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom))),
                    ];
                    return DropdownButtonFormField<String>(
                      initialValue: _caisseId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Caisse'),
                      items: items,
                      onChanged: (v) => setState(() => _caisseId = v),
                      validator: (v) => v == null ? 'Requis' : null,
                    );
                  },
                ),
                const SizedBox(height: 14),
                membresAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Erreur membres : $e'),
                  data: (membres) => DropdownButtonFormField<String?>(
                    initialValue: _membreId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Membre (optionnel)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Aucun / donateur libre —')),
                      ...membres.where((m) => m.actif).map(
                            (m) => DropdownMenuItem(value: m.id, child: Text(m.nomComplet)),
                          ),
                    ],
                    onChanged: (v) => setState(() => _membreId = v),
                  ),
                ),
                if (_membreId == null) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nomLibreCtrl,
                    decoration: const InputDecoration(labelText: 'Nom (si donateur/bénéficiaire non-membre)'),
                  ),
                ],
                const SizedBox(height: 14),
                TextFormField(
                  controller: _montantCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
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
                const SizedBox(height: 14),
                TextFormField(
                  controller: _motifCtrl,
                  decoration: const InputDecoration(labelText: 'Motif (optionnel)'),
                  maxLines: 2,
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(_erreur!, style: const TextStyle(color: AppColors.terre)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _enCours ? null : _enregistrer,
                  child: _enCours
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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
