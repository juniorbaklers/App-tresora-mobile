import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

class CotisationFormScreen extends ConsumerStatefulWidget {
  const CotisationFormScreen({super.key});

  @override
  ConsumerState<CotisationFormScreen> createState() => _CotisationFormScreenState();
}

class _CotisationFormScreenState extends ConsumerState<CotisationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  Periodicite _periodicite = Periodicite.mensuelle;
  DateTime _dateLimite = DateTime.now().add(const Duration(days: 30));
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
      final membres = ref.read(membresStreamProvider).valueOrNull ?? [];
      final membreIdsActifs = membres.where((m) => m.actif).map((m) => m.id).toList();
      final cotisation = Cotisation(
        id: '',
        espaceId: espaceId,
        nom: _nomCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
        periodicite: _periodicite,
        dateLimite: _dateLimite,
        active: true,
      );
      await ref.read(cotisationsServiceProvider).creer(cotisation, membreIdsActifs: membreIdsActifs);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Création impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nbMembresActifs = (ref.watch(membresStreamProvider).valueOrNull ?? [])
        .where((m) => m.actif)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle cotisation')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nomCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description (optionnel)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _montantCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Montant par membre (FCFA)'),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return (n == null || n <= 0) ? 'Montant invalide' : null;
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<Periodicite>(
                  initialValue: _periodicite,
                  decoration: const InputDecoration(labelText: 'Périodicité'),
                  items: Periodicite.values
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.libelle)))
                      .toList(),
                  onChanged: (v) => setState(() => _periodicite = v!),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date limite'),
                  subtitle: Text(formatDate(_dateLimite)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final choisie = await showDatePicker(
                      context: context,
                      initialDate: _dateLimite,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (choisie != null) setState(() => _dateLimite = choisie);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  nbMembresActifs == 0
                      ? 'Aucun membre actif : la cotisation sera créée sans échéance assignée.'
                      : 'Sera assignée aux $nbMembresActifs membre${nbMembresActifs > 1 ? 's' : ''} actif${nbMembresActifs > 1 ? 's' : ''}.',
                  style: const TextStyle(fontSize: 12, color: AppColors.texteSecondaire),
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
                      : const Text('CRÉER'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
