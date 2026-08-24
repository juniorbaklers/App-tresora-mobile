import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../membres/membres_list_screen.dart';
import '../mouvements/mouvements_list_screen.dart';
import '../profil/profil_screen.dart';

/// Coquille principale de l'app avec navigation par onglets, une fois
/// l'utilisateur authentifié.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _ecrans = [
    DashboardScreen(),
    MouvementsListScreen(),
    MembresListScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _ecrans),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Tableau de bord'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Mouvements'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Membres'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
