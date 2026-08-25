import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import '../espaces/espace_selection_screen.dart';

class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profilAsync = ref.watch(monProfilProvider);
    final espaceAvecRole = ref.watch(currentEspaceProvider);

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
              backgroundColor: AppColors.indigoProfond,
              child: Text(
                (profil?.nomComplet.isNotEmpty == true ? profil!.nomComplet[0] : '?').toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
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
            Center(child: Text(user?.email ?? '', style: const TextStyle(color: AppColors.texteSecondaire))),
            const SizedBox(height: 24),
            if (espaceAvecRole != null)
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
                              style: TextStyle(fontSize: 11, color: AppColors.texteSecondaire)),
                          const SizedBox(height: 4),
                          Text(espaceAvecRole.espace.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(espaceAvecRole.role.libelle,
                              style: const TextStyle(fontSize: 12, color: AppColors.texteSecondaire)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(currentEspaceIdProvider.notifier).state = null;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const EspaceSelectionScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('Changer'),
                    ),
                  ],
                ),
              ),
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
