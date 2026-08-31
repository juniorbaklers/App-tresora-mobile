import 'package:supabase_flutter/supabase_flutter.dart';

/// Traduit une exception technique (réseau, Postgrest, Auth) en message
/// lisible en français pour l'utilisateur — à utiliser partout où une
/// exception attrapée est affichée à l'écran, plutôt que son
/// `toString()` brut (ex. `PostgrestException(message: duplicate key...)`)
/// qui n'a de sens que pour quelqu'un qui lit le code.
String messageErreur(Object erreur) {
  if (erreur is PostgrestException) {
    switch (erreur.code) {
      case '23505':
        return 'Cet enregistrement existe déjà.';
      case '23503':
        return 'Cette action fait référence à une donnée qui n\'existe plus '
            '— l\'écran a peut-être besoin d\'être rafraîchi.';
      case '42501':
        return 'Action non autorisée pour ton rôle dans cet espace.';
    }
    return 'Une erreur est survenue côté serveur. Réessaie dans un instant.';
  }
  if (erreur is AuthException) {
    switch (erreur.message) {
      case 'Invalid login credentials':
        return 'Email ou mot de passe incorrect.';
      case 'User already registered':
        return 'Un compte existe déjà avec cet email.';
      case 'Email not confirmed':
        return 'Email non confirmé — vérifie ta boîte de réception.';
    }
    return 'Connexion au compte impossible. Réessaie dans un instant.';
  }
  final texte = erreur.toString();
  if (texte.contains('SocketException') ||
      texte.contains('Failed host lookup') ||
      texte.contains('Connection') ||
      texte.contains('TimeoutException')) {
    return 'Pas de connexion internet. Vérifie ton réseau et réessaie.';
  }
  return 'Une erreur est survenue. Réessaie dans un instant.';
}
