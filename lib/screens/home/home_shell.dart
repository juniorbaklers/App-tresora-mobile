import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/module_espace.dart';
import '../../providers/espace_providers.dart';
import '../../widgets/bandeau_hors_ligne.dart';
import '../cotisations/cotisations_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../evenements/evenements_list_screen.dart';
import '../membres/membres_list_screen.dart';
import '../profil/profil_screen.dart';
import '../tresorerie/tresorerie_list_screen.dart';

class _Onglet {
  final Widget ecran;
  final IconData icone;
  final String libelle;
  const _Onglet(
      {required this.ecran, required this.icone, required this.libelle});
}

/// Coquille principale de l'app avec navigation par onglets, une fois un
/// espace sélectionné. Cotisations/Événements/Membres n'apparaissent que si
/// le module correspondant est activé sur l'espace (Réglages) — Tableau de
/// bord, Trésorerie et Profil restent toujours visibles, comme dans
/// tresora-app (src/lib/nav.ts).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final espace = ref.watch(currentEspaceProvider)?.espace;

    final onglets = [
      const _Onglet(
          ecran: DashboardScreen(),
          icone: Icons.dashboard_outlined,
          libelle: 'Tableau de bord'),
      const _Onglet(
          ecran: TresorerieListScreen(),
          icone: Icons.receipt_long_outlined,
          libelle: 'Trésorerie'),
      if (espace == null || espace.aModule(ModuleEspace.cotisations))
        const _Onglet(
            ecran: CotisationsListScreen(),
            icone: Icons.savings_outlined,
            libelle: 'Cotisations'),
      if (espace == null || espace.aModule(ModuleEspace.evenements))
        const _Onglet(
            ecran: EvenementsListScreen(),
            icone: Icons.celebration_outlined,
            libelle: 'Événements'),
      if (espace == null || espace.aModule(ModuleEspace.membres))
        const _Onglet(
            ecran: MembresListScreen(),
            icone: Icons.people_outline,
            libelle: 'Membres'),
      const _Onglet(
          ecran: ProfilScreen(),
          icone: Icons.person_outline,
          libelle: 'Profil'),
    ];

    final index = _index.clamp(0, onglets.length - 1);

    return Scaffold(
      body: Column(
        children: [
          const BandeauHorsLigne(),
          Expanded(
              child: IndexedStack(
                  index: index, children: [for (final o in onglets) o.ecran])),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final o in onglets)
            BottomNavigationBarItem(icon: Icon(o.icone), label: o.libelle)
        ],
      ),
    );
  }
}
