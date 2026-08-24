import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentification Supabase (email/mot de passe). Le premier compte créé
/// devient automatiquement Trésorier Principal via le trigger SQL
/// `schema_2_trigger.sql` côté base — rien à faire de plus ici.
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> connexion({required String email, required String motDePasse}) async {
    await _client.auth.signInWithPassword(email: email, password: motDePasse);
  }

  Future<void> inscription({
    required String email,
    required String motDePasse,
    required String nomComplet,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: motDePasse,
      data: {'nom_complet': nomComplet},
    );
  }

  Future<void> deconnexion() => _client.auth.signOut();
}
