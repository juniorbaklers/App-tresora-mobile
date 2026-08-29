import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cloture.dart';
import '../models/contribution.dart';
import '../models/cotisation.dart';
import '../models/entree_journal.dart';
import '../models/evenement.dart';
import '../models/invitation.dart';
import '../models/membre.dart';
import '../models/tresorerie.dart';
import '../services/clotures_service.dart';
import '../services/contributions_service.dart';
import '../services/cotisations_service.dart';
import '../services/evenements_service.dart';
import '../services/journal_service.dart';
import '../services/membres_service.dart';
import '../services/rapport_service.dart';
import '../services/recu_service.dart';
import '../services/tresorerie_service.dart';
import 'espace_providers.dart';

final membresServiceProvider = Provider((ref) => MembresService());
final cotisationsServiceProvider = Provider((ref) => CotisationsService());
final paiementsCotisationServiceProvider =
    Provider((ref) => PaiementsCotisationService());
final tranchesServiceProvider = Provider((ref) => TranchesService());
final recettesServiceProvider = Provider((ref) => RecettesService());
final depensesServiceProvider = Provider((ref) => DepensesService());
final evenementsServiceProvider = Provider((ref) => EvenementsService());
final contributionsEvenementServiceProvider =
    Provider((ref) => ContributionsEvenementService());
final contributionsServiceProvider = Provider((ref) => ContributionsService());
final journalServiceProvider = Provider((ref) => JournalService());
final cloturesServiceProvider = Provider((ref) => CloturesService());
final rapportServiceProvider = Provider((ref) => RapportService());
final recuServiceProvider = Provider((ref) => RecuService());

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
  return ref
      .watch(invitationsServiceProvider)
      .streamInvitationsEspace(espaceId);
});

final contributionsEnvoyeesStreamProvider =
    StreamProvider<List<Contribution>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Contribution>[]);
  return ref.watch(contributionsServiceProvider).streamEnvoyees(espaceId);
});

final contributionsRecuesStreamProvider =
    StreamProvider<List<Contribution>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Contribution>[]);
  return ref.watch(contributionsServiceProvider).streamRecues(espaceId);
});

final versementsContributionProvider =
    StreamProvider.family((ref, String contributionId) {
  return ref
      .watch(contributionsServiceProvider)
      .streamVersements(contributionId);
});

final journalStreamProvider = StreamProvider<List<EntreeJournal>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<EntreeJournal>[]);
  return ref.watch(journalServiceProvider).streamJournal(espaceId);
});

final cloturesStreamProvider = StreamProvider<List<Cloture>>((ref) {
  final espaceId = ref.watch(currentEspaceIdProvider);
  if (espaceId == null) return Stream.value(<Cloture>[]);
  return ref.watch(cloturesServiceProvider).streamClotures(espaceId);
});

/// Paiements d'une cotisation précise — provider "family" paramétré par
/// l'id de la cotisation (utilisé sur l'écran de détail).
final paiementsCotisationProvider =
    StreamProvider.family((ref, String cotisationId) {
  return ref
      .watch(paiementsCotisationServiceProvider)
      .streamPaiements(cotisationId);
});

final tranchesProvider =
    StreamProvider.family((ref, String paiementCotisationId) {
  return ref
      .watch(tranchesServiceProvider)
      .streamTranches(paiementCotisationId);
});

/// Paiements de TOUTES les cotisations de l'espace courant, en une seule
/// requête (pas un flux temps réel par cotisation) — utilisé par les écrans
/// qui doivent agréger sur l'ensemble des cotisations (Paiement, tableau de
/// bord groupe, fiche membre) pour éviter d'ouvrir des dizaines de
/// connexions temps réel simultanées quand l'espace a beaucoup de
/// cotisations.
final paiementsEspaceProvider =
    FutureProvider.autoDispose<List<PaiementCotisation>>((ref) async {
  final espaceId = ref.watch(currentEspaceIdProvider);
  final cotisations = ref.watch(cotisationsStreamProvider).valueOrNull ?? [];
  if (cotisations.isEmpty) return [];
  return ref.watch(paiementsCotisationServiceProvider).fetchPourCotisations(
      cotisations.map((c) => c.id).toList(),
      cacheKey: espaceId ?? 'defaut');
});

/// Tranches des paiements (avec versement) d'une cotisation précise, en une
/// seule requête — utilisé pour "derniers paiements" sur le tableau de bord
/// groupe, à la place d'un flux temps réel par paiement.
final tranchesCotisationProvider =
    FutureProvider.autoDispose.family<List<Tranche>, String>(
        (ref, cotisationId) async {
  final paiements =
      ref.watch(paiementsCotisationProvider(cotisationId)).valueOrNull ?? [];
  final ids = paiements
      .where((p) => p.montantPaye > 0)
      .map((p) => p.id)
      .toList();
  if (ids.isEmpty) return [];
  return ref
      .watch(tranchesServiceProvider)
      .fetchPourPaiements(ids, cacheKey: cotisationId);
});

/// Fiches de contribution d'un événement précis — provider "family" utilisé
/// sur l'écran de détail (analogue à tranchesProvider pour les cotisations).
final contributionsEvenementProvider =
    StreamProvider.family((ref, String evenementId) {
  return ref
      .watch(contributionsEvenementServiceProvider)
      .streamContributions(evenementId);
});
