import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_theme.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _enCours = false;
  String? _erreur;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _connexion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(authServiceProvider).connexion(
            email: _emailCtrl.text.trim(),
            motDePasse: _motDePasseCtrl.text,
          );
    } catch (e) {
      setState(() => _erreur = "Connexion impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.church, size: 56, color: AppColors.bleu),
                    const SizedBox(height: 12),
                    Text(
                      'Trésora',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.bleu,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gestion de trésorerie d\'église',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _motDePasseCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mot de passe'),
                      validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 caractères' : null,
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 12),
                      Text(_erreur!, style: const TextStyle(color: AppColors.rouge)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _enCours ? null : _connexion,
                      child: _enCours
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('SE CONNECTER'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _enCours
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignupScreen()),
                              ),
                      child: const Text('Créer un compte'),
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
