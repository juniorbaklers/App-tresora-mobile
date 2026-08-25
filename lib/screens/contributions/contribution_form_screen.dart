import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contribution.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

class ContributionFormScreen extends ConsumerStatefulWidget {
  const ContributionFormScreen({super.key});

  @override
  ConsumerState<ContributionFormScreen> createState() =>
      _ContributionFormScreenState();
}

class _ContributionFormScreenState
    extends ConsumerState<ContributionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projetCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  DateTime _dateLimite = DateTime.now().add(const Duration(days: 30));
  String? _espaceCibleId;
  bool _enCours = false;
  String? _erreur;

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    final espaceId = ref.read(currentEspaceIdProvider);
    if (espaceId == null || _espaceCibleId == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(contributionsServiceProvider).creer(Contribution(
            id: '',
            projet: _projetCtrl.text.trim(),
            description: _descriptionCtrl.text.trim(),
            espaceDemandeurId: espaceId,
            espaceCibleId: _espaceCibleId!,
            montantDemande:
                double.parse(_montantCtrl.text.replaceAll(',', '.')),
            montantRecu: 0,
            dateLimite: _dateLimite,
            statut: StatutContribution.enAttente,
          ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Envoi impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final espaceCourantId = ref.watch(currentEspaceIdProvider);
    final autresEspaces = (ref.watch(mesEspacesProvider).valueOrNull ?? [])
        .where((e) => e.espace.id != espaceCourantId)
        .map((e) => e.espace)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Demander une contribution')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (autresEspaces.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: Text(
                      'Tu ne gères qu\'un seul espace pour l\'instant : rejoins ou crée un autre '
                      'espace pour pouvoir lui demander une contribution.',
                      style: TextStyle(color: AppColors.texteSecondaire),
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _espaceCibleId,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Espace sollicité'),
                    items: [
                      for (final e in autresEspaces)
                        DropdownMenuItem(value: e.id, child: Text(e.nom)),
                    ],
                    onChanged: (v) => setState(() => _espaceCibleId = v),
                    validator: (v) => v == null ? 'Choisis un espace' : null,
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _projetCtrl,
                  decoration: const InputDecoration(labelText: 'Projet'),
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
                TextFormField(
                  controller: _montantCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Montant demandé (FCFA)'),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return (n == null || n <= 0) ? 'Montant invalide' : null;
                  },
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
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (choisie != null) setState(() => _dateLimite = choisie);
                  },
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(_erreur!,
                      style: const TextStyle(color: AppColors.terre)),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      (_enCours || autresEspaces.isEmpty) ? null : _envoyer,
                  child: _enCours
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('ENVOYER LA DEMANDE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
