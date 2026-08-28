import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache local générique (JSON) pour la lecture hors-ligne des dernières
/// données synchronisées. Pas d'écriture hors-ligne : c'est un simple
/// instantané, pas une file de synchronisation.
class OfflineCache {
  static Future<void> sauvegarder(String cle, Object donnees) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cache_$cle', jsonEncode(donnees));
  }

  static Future<dynamic> charger(String cle) async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getString('cache_$cle');
    if (brut == null) return null;
    try {
      return jsonDecode(brut);
    } catch (_) {
      return null;
    }
  }
}

/// Enrobe une requête Supabase ponctuelle (`.select()`, pas un flux temps
/// réel) : tente le réseau, recache le résultat s'il réussit ; s'il échoue
/// (hors-ligne), retombe sur le dernier instantané local au lieu de
/// remonter l'erreur — pendant du [avecCacheHorsLigne] pour les écrans qui
/// agrègent via une requête ponctuelle plutôt qu'un flux (Paiement rapide,
/// tableau de bord groupe, fiche membre : voir
/// `CotisationsService.fetchPourCotisations`/`fetchPourPaiements`).
Future<List<Map<String, dynamic>>> avecCacheHorsLigneFuture(
  String cle,
  Future<List<Map<String, dynamic>>> Function() recuperer,
) async {
  try {
    final lignes = await recuperer();
    OfflineCache.sauvegarder(cle, lignes);
    return lignes;
  } catch (_) {
    final brut = await OfflineCache.charger(cle);
    if (brut is List) return brut.cast<Map<String, dynamic>>();
    rethrow;
  }
}

/// Enrobe un flux Supabase de lignes brutes (avant `.map(Modele.fromMap)`) :
/// émet immédiatement le cache local au démarrage pour un rendu instantané
/// même hors-ligne, puis les données réseau dès qu'elles arrivent (en les
/// recachant à chaque fois). Une erreur réseau (perte de connexion) est
/// avalée silencieusement — l'écran garde les dernières données connues
/// plutôt que d'afficher une erreur.
Stream<List<Map<String, dynamic>>> avecCacheHorsLigne(
  String cle,
  Stream<List<Map<String, dynamic>>> flux,
) {
  late StreamController<List<Map<String, dynamic>>> controller;
  StreamSubscription<List<Map<String, dynamic>>>? abonnement;

  controller = StreamController<List<Map<String, dynamic>>>(
    onListen: () async {
      final brut = await OfflineCache.charger(cle);
      if (brut is List && !controller.isClosed) {
        controller.add(brut.cast<Map<String, dynamic>>());
      }
      abonnement = flux.listen(
        (lignes) {
          OfflineCache.sauvegarder(cle, lignes);
          if (!controller.isClosed) controller.add(lignes);
        },
        onError: (_, __) {},
      );
    },
    onCancel: () => abonnement?.cancel(),
  );
  return controller.stream;
}
