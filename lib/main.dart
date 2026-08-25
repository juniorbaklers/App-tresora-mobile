import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'providers/auth_providers.dart';
import 'screens/auth/login_screen.dart';
import 'screens/espaces/espace_selection_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Les polices de marque ne sont pas encore embarquées comme assets locaux :
  // sans cette ligne, google_fonts tente de les télécharger au premier
  // affichage de chaque écran (à chaque lancement tant que le cache est
  // froid), ce qui bloque le rendu sur une requête réseau et donne une
  // impression de lenteur, surtout sur réseau mobile instable. On retombe
  // sur la police système en attendant un vrai embarquement des .ttf.
  GoogleFonts.config.allowRuntimeFetching = false;
  await initializeDateFormatting('fr_FR');
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );
  runApp(const ProviderScope(child: TresoraApp()));
}

class TresoraApp extends StatelessWidget {
  const TresoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trésora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}

/// Bascule entre l'écran de connexion et la sélection d'espace selon
/// l'état de la session Supabase — se met à jour automatiquement à la
/// connexion/déconnexion. Une fois connecté, l'utilisateur choisit
/// toujours quel espace gérer (aucun n'est présélectionné).
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authStateProvider);
    final user = ref.watch(currentUserProvider);
    return user == null ? const LoginScreen() : const EspaceSelectionScreen();
  }
}
