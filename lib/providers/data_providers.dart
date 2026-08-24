import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/caisse.dart';
import '../models/membre.dart';
import '../models/mouvement.dart';
import '../services/caisses_service.dart';
import '../services/membres_service.dart';
import '../services/mouvements_service.dart';

final caissesServiceProvider = Provider((ref) => CaissesService());
final membresServiceProvider = Provider((ref) => MembresService());
final mouvementsServiceProvider = Provider((ref) => MouvementsService());

final caissesStreamProvider = StreamProvider<List<Caisse>>((ref) {
  return ref.watch(caissesServiceProvider).streamCaisses();
});

final membresStreamProvider = StreamProvider<List<Membre>>((ref) {
  return ref.watch(membresServiceProvider).streamMembres();
});

final mouvementsStreamProvider = StreamProvider<List<Mouvement>>((ref) {
  return ref.watch(mouvementsServiceProvider).streamMouvements();
});
