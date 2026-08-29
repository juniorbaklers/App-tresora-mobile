import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entree_journal.dart';
import '../../providers/auth_providers.dart';
import '../../providers/connectivite_provider.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import '../auth/login_screen.dart';
import '../espaces/espace_selection_screen.dart';
import '../journal/journal_list_screen.dart';
import '../reglages/reglages_espace_screen.dart';
import '../reglages/roles_permissions_screen.dart';

/// Habillage d'après la maquette « Profil, audit & hors ligne » du canvas
/// de design : statut de connexion réel (pas de compteur d'écritures/sync
/// fabriqué, cette app n'a pas de file de synchronisation — voir
/// cache_hors_ligne.dart), aperçu du journal d'audit, accès rôles &
/// permissions. Pas de « mode démonstration » : cette fonctionnalité de la
/// maquette n'existe pas dans l'app.
class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profilAsync = ref.watch(monProfilProvider);
    final espaceAvecRole = ref.watch(currentEspaceProvider);
    final horsLigne = ref.watch(estHorsLigneProvider).valueOrNull ?? false;
    final journal = espaceAvecRole == null
        ? const <EntreeJournal>[]
        : ref.watch(journalStreamProvider).valueOrNull ?? const <EntreeJournal>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: profilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (profil) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.graphite,
              child: Text(
                (profil?.nomComplet.isNotEmpty == true
                        ? profil!.nomComplet[0]
                        : '?')
                    .toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                profil?.nomComplet ?? '—',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Center(
                child: Text(user?.email ?? '',
                    style: const TextStyle(color: AppColors.texteSecondaire))),
            const SizedBox(height: 24),
            if (espaceAvecRole != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.carte,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.bordure),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ESPACE ACTUEL',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.texteSecondaire)),
                          const SizedBox(height: 4),
                          Text(espaceAvecRole.espace.nom,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(espaceAvecRole.role.libelle,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.texteSecondaire)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(currentEspaceIdProvider.notifier).state = null;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const EspaceSelectionScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Changer'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.carte,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.bordure),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: horsLigne ? AppColors.or : AppColors.palme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      horsLigne
                          ? 'Hors ligne · lecture seule'
                          : 'En ligne',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.texteEncre),
                    ),
                  ),
                ],
              ),
            ),
            if (espaceAvecRole != null)
              RoleGate(
                peutAcceder: (r) => r.peutAdministrer,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: const Text('Réglages de l\'espace'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ReglagesEspaceScreen()),
                      ),
                    ),
                  ),
                ),
              ),
            if (espaceAvecRole != null)
              RoleGate(
                peutAcceder: (r) => r.peutAdministrer,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.shield_outlined),
                      title: const Text('Rôles & permissions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RolesPermissionsScreen()),
                      ),
                    ),
                  ),
                ),
              ),
            if (espaceAvecRole != null && journal.isNotEmpty) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Journal d\'audit',
                      style: Theme.of(context).textTheme.titleMedium),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const JournalListScreen()),
                    ),
                    child: const Text('Tout voir',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.terre)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.carte,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.bordure),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entree in journal.take(4)) ...[
                      if (entree != journal.first) const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.terre,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(entree.action,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.texteEncre)),
                                Text(
                                    '${entree.utilisateur} · ${formatDate(entree.date)}',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.texteSecondaire)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).deconnexion();
                ref.read(currentEspaceIdProvider.notifier).state = null;
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.terre,
                side: const BorderSide(color: AppColors.terre),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
