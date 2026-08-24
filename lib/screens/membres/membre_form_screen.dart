import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/membre.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';

class MembreFormScreen extends ConsumerStatefulWidget {
  final Membre? membre;

  const MembreFormScreen({super.key, this.membre});

  @override
  ConsumerState<MembreFormScreen> createState() => _MembreFormScreenState();
}

class _MembreFormScreenState extends ConsumerState<MembreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nomCtrl = TextEditingController(text: widget.membre?.nomComplet ?? '');
  late final _telCtrl = TextEditingController(text: widget.membre?.telephone ?? '');
  bool _enCours = false;
  String? _erreur;

  bool get _modification => widget.membre != null;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final service = ref.read(membresServiceProvider);
      if (_modification) {
        await service.modifier(widget.membre!.id, {
          'nom_complet': _nomCtrl.text.trim(),
          'telephone': _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
        });
      } else {
        await service.creer(Membre(
          id: '',
          nomComplet: _nomCtrl.text.trim(),
          telephone: _telCtrl.text.trim().isEmpty ? null : _telCtrl.text.trim(),
          actif: true,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Enregistrement impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_modification ? 'Modifier le membre' : 'Nouveau membre')),
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
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(_erreur!, style: const TextStyle(color: AppColors.rouge)),
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
                      : Text(_modification ? 'ENREGISTRER LES MODIFICATIONS' : 'AJOUTER'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
