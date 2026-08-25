import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contribution.dart';
import '../models/cotisation.dart';
import '../models/evenement.dart';
import '../models/invitation.dart';
import '../models/membre.dart';
import '../models/tresorerie.dart';
import '../services/contributions_service.dart';
import '../services/cotisations_service.dart';
import '../services/evenements_service.dart';
import '../services/membres_service.dart';
import '../services/tresorerie_service.dart';
import 'espace_providers.dart';

final membresServiceProvider = Provider((ref) => MembresService());
final cotisationsServiceProvider = Provider((ref) => CotisationsService());
final paiementsCotisationServiceProvider = Provider((ref) => PaiementsCotisationService());
final tranchesServiceProvider = Provider((ref) => TranchesService());
final recettesServiceProvider = Provider((ref) => RecettesService());
final depensesServiceProvider = Provider((ref) => DepensesService());
final evenementsServiceProvider = Provider((ref) => EvenementsService());
final contributionsServiceProvider = Provider((ref) => ContributionsService());

/// Tous les providers de données ci-dessous sont scopés à l'espace
/// sélectionné (currentEspaceIdProvider) : flux vide tant qu'aucun espace
/// n'est choisi.

final membresStreamProvider = StreamProvider<List<Membre>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Membre>[]);
  return ref.watch(membresServiceProvider).streamMembres(espaceId);
});

final cotisationsStreamProvider = StreamProvider<List<Cotisation>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Cotisation>[]);
  return ref.watch(cotisationsServiceProvider).streamCotisations(espaceId);
});

final recettesStreamProvider = StreamProvider<List<Recette>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Recette>[]);
  return ref.watch(recettesServiceProvider).streamRecettes(espaceId);
});

final depensesStreamProvider = StreamProvider<List<Depense>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Depense>[]);
  return ref.watch(depensesServiceProvider).streamDepenses(espaceId);
});

final evenementsStreamProvider = StreamProvider<List<Evenement>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Evenement>[]);
  return ref.watch(evenementsServiceProvider).streamEvenements(espaceId);
});

final invitationsEspaceStreamProvider = StreamProvider<List<Invitation>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Invitation>[]);
  return ref.watch(invitationsServiceProvider).streamInvitationsEspace(espaceId);
});

final contributionsEnvoyeesStreamProvider = StreamProvider<List<Contribution>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Contribution>[]);
  return ref.watch(contributionsServiceProvider).streamEnvoyees(espaceId);
});

final contributionsRecuesStreamProvider = StreamProvider<List<Contribution>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Contribution>[]);
  return ref.watch(contributionsServiceProvider).streamRecues(espaceId);
});

final versementsContributionProvider = StreamProvider.family((ref, String contributionId) {
  return ref.watch(contributionsServiceProvider).streamVersements(contributionId);
});

/// Paiements d'une cotisation précise — provider "family" paramétré par
/// l'id de la cotisation (utilisé sur l'écran de détail).
final paiementsCotisationProvider =
    StreamProvider.family((ref, String cotisationId) {
  return ref.watch(paiementsCotisationServiceProvider).streamPaiements(cotisationId);
});

final tranchesProvider = StreamProvider.family((ref, String paiementCotisationId) {
  return ref.watch(tranchesServiceProvider).streamTranches(paiementCotisationId);
});
