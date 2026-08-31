import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motif.dart';
import '../../utils/erreurs.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _enCours = false;
  String? _erreur;
  bool _inscritOk = false;

  Future<void> _inscription() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(authServiceProvider).inscription(
            email: _emailCtrl.text.trim(),
            motDePasse: _motDePasseCtrl.text,
            nomComplet: _nomCtrl.text.trim(),
          );
      setState(() => _inscritOk = true);
    } catch (e) {
      setState(() => _erreur = "Inscription impossible : ${messageErreur(e)}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _inscritOk
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mark_email_read,
                            size: 56, color: AppColors.palme),
                        const SizedBox(height: 16),
                        const Text(
                          'Compte créé. Vérifie ta boîte mail pour confirmer ton adresse, '
                          'puis connecte-toi.\n\nLe premier compte créé sur la base devient '
                          'automatiquement Trésorier Principal.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Retour à la connexion'),
                        ),
                      ],
                    )
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.graphite,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.church,
                                size: 28, color: AppColors.or),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Trésora',
                            textAlign: TextAlign.center,
                            style: AppFonts.heading(
                                fontSize: 24, color: AppColors.graphite),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: SizedBox(
                                width: 100,
                                child: BandeTissee(
                                    tonalite: Tonalite.mixte, epaisseur: 4)),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nomCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Nom complet'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Requis'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(labelText: 'Email'),
                            validator: (v) => (v == null || !v.contains('@'))
                                ? 'Email invalide'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _motDePasseCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Mot de passe'),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Minimum 6 caractères'
                                : null,
                          ),
                          if (_erreur != null) ...[
                            const SizedBox(height: 12),
                            Text(_erreur!,
                                style: const TextStyle(color: AppColors.terre)),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _enCours ? null : _inscription,
                            child: _enCours
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('CRÉER LE COMPTE'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
