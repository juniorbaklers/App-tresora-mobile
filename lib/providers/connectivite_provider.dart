import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// true si aucune interface réseau n'est active. Un signal réseau présent
/// ne garantit pas un accès Internet réel, mais c'est un indicateur simple
/// et suffisant pour afficher un bandeau "hors-ligne" à l'utilisateur.
final estHorsLigneProvider = StreamProvider<bool>((ref) {
  return Connectivity()
      .onConnectivityChanged
      .map((resultats) => resultats.every((r) => r == ConnectivityResult.none));
});
