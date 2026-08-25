import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/evenement.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

class EvenementFormScreen extends ConsumerStatefulWidget {
  const EvenementFormScreen({super.key});

  @override
  ConsumerState<EvenementFormScreen> createState() =>
      _EvenementFormScreenState();
}

class _EvenementFormScreenState extends ConsumerState<EvenementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _montantCibleCtrl = TextEditingController();
  final _montantSuggereCtrl = TextEditingController();
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now().add(const Duration(days: 7));
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
      final evenement = Evenement(
        id: '',
        espaceId: espaceId,
        nom: _nomCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        dateDebut: _dateDebut,
        dateFin: _dateFin,
        montantCible:
            double.tryParse(_montantCibleCtrl.text.replaceAll(',', '.')),
        montantSuggere:
            double.tryParse(_montantSuggereCtrl.text.replaceAll(',', '.')),
        montantCollecte: 0,
        participants: 0,
        statut: StatutEvenement.planifie,
      );
      await ref.read(evenementsServiceProvider).creer(evenement);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Création impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel événement')),
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
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Description (optionnel)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date de début'),
                  subtitle: Text(formatDate(_dateDebut)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final choisie = await showDatePicker(
                      context: context,
                      initialDate: _dateDebut,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (choisie != null) {
                      setState(() {
                        _dateDebut = choisie;
                        if (_dateFin.isBefore(_dateDebut)) {
                          _dateFin = _dateDebut;
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date de fin'),
                  subtitle: Text(formatDate(_dateFin)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final choisie = await showDatePicker(
                      context: context,
                      initialDate: _dateFin,
                      firstDate: _dateDebut,
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (choisie != null) setState(() => _dateFin = choisie);
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _montantCibleCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Objectif (FCFA, optionnel)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    return (n == null || n <= 0) ? 'Montant invalide' : null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _montantSuggereCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Montant suggéré par personne (optionnel)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    return (n == null || n <= 0) ? 'Montant invalide' : null;
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
