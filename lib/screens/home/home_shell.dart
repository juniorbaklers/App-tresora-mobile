import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/bandeau_hors_ligne.dart';
import '../cotisations/cotisations_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../evenements/evenements_list_screen.dart';
import '../membres/membres_list_screen.dart';
import '../profil/profil_screen.dart';
import '../tresorerie/tresorerie_list_screen.dart';

/// Coquille principale de l'app avec navigation par onglets, une fois un
/// espace sélectionné.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  static const _ecrans = [
    DashboardScreen(),
    TresorerieListScreen(),
    CotisationsListScreen(),
    EvenementsListScreen(),
    MembresListScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const BandeauHorsLigne(),
          Expanded(child: IndexedStack(index: _index, children: _ecrans)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined), label: 'Tableau de bord'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined), label: 'Trésorerie'),
          BottomNavigationBarItem(
              icon: Icon(Icons.savings_outlined), label: 'Cotisations'),
          BottomNavigationBarItem(
              icon: Icon(Icons.celebration_outlined), label: 'Événements'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: 'Membres'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
