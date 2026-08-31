import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cloture.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/erreurs.dart';

class ClotureFormScreen extends ConsumerStatefulWidget {
  const ClotureFormScreen({super.key});

  @override
  ConsumerState<ClotureFormScreen> createState() => _ClotureFormScreenState();
}

class _ClotureFormScreenState extends ConsumerState<ClotureFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _culteCtrl = TextEditingController();
  final _offrandeOrdinaireCtrl = TextEditingController(text: '0');
  final _offrandeSpecialeCtrl = TextEditingController(text: '0');
  final _dimesCtrl = TextEditingController(text: '0');
  final _autresRecettesCtrl = TextEditingController(text: '0');
  final _totalCompteCtrl = TextEditingController();
  final _justificationCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _enCours = false;
  String? _erreur;

  double _n(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    final espaceId = ref.read(currentEspaceIdProvider);
    final user = ref.read(currentUserProvider);
    if (espaceId == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(cloturesServiceProvider).creer(Cloture(
            id: '',
            espaceId: espaceId,
            date: _date,
            culte: _culteCtrl.text.trim(),
            offrandeOrdinaire: _n(_offrandeOrdinaireCtrl),
            offrandeSpeciale: _n(_offrandeSpecialeCtrl),
            dimes: _n(_dimesCtrl),
            autresRecettes: _n(_autresRecettesCtrl),
            totalCompte: _n(_totalCompteCtrl),
            responsable: user?.email ?? '',
            justification: _justificationCtrl.text.trim().isEmpty
                ? null
                : _justificationCtrl.text.trim(),
          ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Enregistrement impossible : ${messageErreur(e)}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDeclare = _n(_offrandeOrdinaireCtrl) +
        _n(_offrandeSpecialeCtrl) +
        _n(_dimesCtrl) +
        _n(_autresRecettesCtrl);
    final ecart = _n(_totalCompteCtrl) - totalDeclare;

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle clôture')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                  controller: _culteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Culte (ex: Matin, Soir — optionnel)'),
                ),
                const SizedBox(height: 20),
                Text('DÉCLARÉ (issu des écritures de recette)',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.texteSecondaire,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _champMontant(_offrandeOrdinaireCtrl, 'Offrande ordinaire'),
                const SizedBox(height: 14),
                _champMontant(_offrandeSpecialeCtrl, 'Offrande spéciale'),
                const SizedBox(height: 14),
                _champMontant(_dimesCtrl, 'Dîmes'),
                const SizedBox(height: 14),
                _champMontant(_autresRecettesCtrl, 'Autres recettes'),
                const SizedBox(height: 20),
                Text('COMPTÉ EN CAISSE',
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.texteSecondaire,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _champMontant(_totalCompteCtrl, 'Total compté', requis: true),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.carte,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.bordure),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Écart',
                          style: TextStyle(color: AppColors.texteSecondaire)),
                      Text(
                        ecart == 0
                            ? 'Aucun'
                            : '${ecart > 0 ? '+' : ''}${formatMontant(ecart)}',
                        style: AppFonts.montant(
                            fontSize: 15,
                            color:
                                ecart == 0 ? AppColors.palme : AppColors.terre),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _justificationCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Justification de l\'écart (optionnel)'),
                  maxLines: 2,
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

  Widget _champMontant(TextEditingController controller, String label,
      {bool requis = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: '$label (FCFA)'),
      onChanged: (_) => setState(() {}),
      validator: requis
          ? (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              return (n == null) ? 'Montant invalide' : null;
            }
          : null,
    );
  }
}
