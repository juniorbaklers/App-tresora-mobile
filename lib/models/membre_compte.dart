import 'profil.dart';
import 'role.dart';

/// Un utilisateur ayant un compte dans l'espace (ligne `espace_membres`
/// combinée à son `profil`) — distinct de `Membre` (registre nominatif des
/// cotisants, qui n'ont pas forcément de compte dans l'app). Utilisé pour
/// la gestion des rôles dans l'écran Réglages.
class MembreCompte {
  final Profil profil;
  final RoleEspace role;

  MembreCompte({required this.profil, required this.role});
}
