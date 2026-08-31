import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentification Supabase (email/mot de passe). Un nouveau compte ne
/// reçoit qu'un profil (trigger `gerer_nouvel_utilisateur`,
/// `schema_2_triggers.sql`) — aucun espace ni rôle automatique. Il doit
/// ensuite créer son propre espace (il en devient `proprietaire`) ou
/// accepter une invitation pour rejoindre celui de quelqu'un d'autre.
class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> connexion(
      {required String email, required String motDePasse}) async {
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
