import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profil.dart';
import '../services/auth_service.dart';
import '../services/profils_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final profilsServiceProvider = Provider((ref) => ProfilsService());

/// Émet à chaque connexion/déconnexion.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Utilisateur Supabase courant (null si déconnecté).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

/// Identité globale (nom, email) de l'utilisateur connecté. Le rôle, lui,
/// est spécifique à chaque espace — voir currentRoleProvider.
final monProfilProvider = StreamProvider<Profil?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(null);
  return ref.watch(profilsServiceProvider).streamMonProfil(user.id);
});
