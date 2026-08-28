import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/module_espace.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bandeau_hors_ligne.dart';
import '../cotisations/cotisations_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../evenements/evenements_list_screen.dart';
import '../membres/membres_list_screen.dart';
import '../profil/profil_screen.dart';
import '../tresorerie/tresorerie_form_screen.dart';
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
      bottomNavigationBar: _NavBasse(
        onglets: onglets,
        index: index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}

/// Nav du bas d'après la maquette « Accueil de l'espace » : fond blanc, trait
/// haut fin, losange (carré pivoté) comme repère d'onglet actif plutôt qu'un
/// simple changement de teinte, bouton central sombre en saillie pour saisir
/// une écriture sans passer par l'onglet Trésorerie.
class _NavBasse extends StatelessWidget {
  final List<_Onglet> onglets;
  final int index;
  final ValueChanged<int> onTap;

  const _NavBasse(
      {required this.onglets, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final milieu = onglets.length ~/ 2;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.carte,
        border: Border(top: BorderSide(color: AppColors.bordure)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < onglets.length; i++) ...[
                if (i == milieu) const _BoutonSaisieRapide(),
                Expanded(
                  child: _OngletBouton(
                    onglet: onglets[i],
                    actif: i == index,
                    onTap: () => onTap(i),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OngletBouton extends StatelessWidget {
  final _Onglet onglet;
  final bool actif;
  final VoidCallback onTap;

  const _OngletBouton(
      {required this.onglet, required this.actif, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final couleur = actif ? AppColors.terre : AppColors.texteSecondaire;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.rotate(
            angle: .785398, // 45°
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: actif ? AppColors.terre : AppColors.bordure,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Icon(onglet.icone, size: 20, color: couleur),
          const SizedBox(height: 2),
          Text(
            onglet.libelle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 9,
                fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                color: couleur),
          ),
        ],
      ),
    );
  }
}

class _BoutonSaisieRapide extends StatelessWidget {
  const _BoutonSaisieRapide();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Transform.translate(
        offset: const Offset(0, -18),
        child: Material(
          color: AppColors.graphite,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: AppColors.graphite.withValues(alpha: .6),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TresorerieFormScreen()),
            ),
            child: const SizedBox(
              width: 50,
              height: 50,
              child: Icon(Icons.add, color: AppColors.or, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
