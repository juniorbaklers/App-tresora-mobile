import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/contribution.dart';
import '../../models/cotisation.dart';
import '../../models/espace.dart';
import '../../models/evenement.dart';
import '../../models/membre.dart';
import '../../models/module_espace.dart';
import '../../models/tresorerie.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/motif.dart';
import '../../widgets/stat_card.dart';
import '../contributions/contributions_list_screen.dart';
import '../notifications/notifications_list_screen.dart';

/// Tableau de bord : l'écran s'adapte au type d'espace, comme tresora-app
/// (src/app/espace/[espaceId]/dashboard/page.tsx) qui choisit entre
/// `DashboardEglise` et `DashboardGroupe` selon `espace.type === "eglise"`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espace = ref.watch(currentEspaceProvider)?.espace;
    final notificationsNonLues =
        (ref.watch(mesNotificationsProvider).valueOrNull ?? [])
            .where((n) => !n.lue)
            .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(espace?.nom ?? 'Tableau de bord'),
        actions: [
          if (espace == null || espace.aModule(ModuleEspace.contributions))
            IconButton(
              icon: const Icon(Icons.compare_arrows),
              tooltip: 'Contributions inter-espaces',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ContributionsListScreen()),
              ),
            ),
          IconButton(
            icon: Badge(
              label: Text('$notificationsNonLues'),
              isLabelVisible: notificationsNonLues > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const NotificationsListScreen()),
            ),
          ),
        ],
      ),
      body: espace == null || espace.type == EspaceType.eglise
          ? const _CorpsEglise()
          : _CorpsGroupe(espace: espace),
    );
  }
}

class _CorpsEglise extends ConsumerWidget {
  const _CorpsEglise();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espace = ref.watch(currentEspaceProvider)?.espace;
    final recettesAsync = ref.watch(recettesStreamProvider);
    final depensesAsync = ref.watch(depensesStreamProvider);

    return recettesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (recettes) => depensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (depenses) {
          final annee = DateTime.now().year;
          final totalRecettes = recettes.fold(0.0, (a, r) => a + r.montant);
          final totalDepenses = depenses.fold(0.0, (a, d) => a + d.montant);
          final solde =
              (espace?.soldeInitial ?? 0) + totalRecettes - totalDepenses;
          final totalDimes = recettes
              .where((r) => r.categorie == CategorieRecette.dime)
              .fold(0.0, (a, r) => a + r.montant);
          final totalOffrandes = recettes
              .where((r) =>
                  r.categorie == CategorieRecette.offrandeOrdinaire ||
                  r.categorie == CategorieRecette.offrandeSpeciale ||
                  r.categorie == CategorieRecette.offrandeCulteSoir)
              .fold(0.0, (a, r) => a + r.montant);
          final afficherDimes = espace?.aModule(ModuleEspace.dimes) ?? false;
          final afficherOffrandes =
              espace?.aModule(ModuleEspace.offrandes) ?? false;

          final entreesParMois = List<double>.filled(12, 0);
          final depensesParMois = List<double>.filled(12, 0);
          for (final r in recettes) {
            if (r.date.year == annee) {
              entreesParMois[r.date.month - 1] += r.montant;
            }
          }
          for (final d in depenses) {
            if (d.date.year == annee) {
              depensesParMois[d.date.month - 1] += d.montant;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recettesStreamProvider);
              ref.invalidate(depensesStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                      titre: 'TOTAL RECETTES',
                      montant: totalRecettes,
                      sousTitre: 'Cette année',
                      couleurFond: AppColors.palme,
                      couleurTexte: Colors.white,
                      tonalite: Tonalite.palme,
                    ),
                    StatCard(
                      titre: 'TOTAL DÉPENSES',
                      montant: totalDepenses,
                      sousTitre: 'Cette année',
                      couleurFond: AppColors.terre,
                      couleurTexte: Colors.white,
                      tonalite: Tonalite.terre,
                    ),
                    StatCard(
                      titre: 'SOLDE',
                      montant: solde,
                      sousTitre: espace?.nom ?? '',
                      tonalite: Tonalite.indigo,
                    ),
                    if (afficherDimes)
                      StatCard(
                        titre: 'DÎMES',
                        montant: totalDimes,
                        sousTitre: 'Cette année',
                        tonalite: Tonalite.or,
                      ),
                    if (afficherOffrandes)
                      StatCard(
                        titre: 'OFFRANDES',
                        montant: totalOffrandes,
                        sousTitre: 'Cette année',
                        tonalite: Tonalite.mixte,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Recettes / Dépenses $annee',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: _GraphiqueMensuel(
                      entrees: entreesParMois, depenses: depensesParMois),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Variante du tableau de bord pour les espaces non-église (groupe,
/// association, perso) : suivi de la cotisation en cours plutôt que
/// dîmes/offrandes, événements actifs, contributions demandées par l'espace
/// parent. Reprend `DashboardGroupe` de tresora-app
/// (src/components/dashboard/dashboard-groupe.tsx).
class _CorpsGroupe extends ConsumerWidget {
  final Espace espace;

  const _CorpsGroupe({required this.espace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recettesAsync = ref.watch(recettesStreamProvider);
    final depensesAsync = ref.watch(depensesStreamProvider);

    return recettesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur : $e')),
      data: (recettes) => depensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (depenses) => _CorpsGroupeCharge(
            espace: espace, recettes: recettes, depenses: depenses),
      ),
    );
  }
}

class _CorpsGroupeCharge extends ConsumerWidget {
  final Espace espace;
  final List<Recette> recettes;
  final List<Depense> depenses;

  const _CorpsGroupeCharge({
    required this.espace,
    required this.recettes,
    required this.depenses,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final annee = DateTime.now().year;
    final totalRecettes = recettes.fold(0.0, (a, r) => a + r.montant);
    final totalDepenses = depenses.fold(0.0, (a, d) => a + d.montant);
    final solde = espace.soldeInitial + totalRecettes - totalDepenses;

    final cotisations = ref.watch(cotisationsStreamProvider).valueOrNull ?? [];
    final cotisationActive =
        cotisations.where((c) => c.active).firstOrNull;
    final paiements = cotisationActive == null
        ? <PaiementCotisation>[]
        : ref.watch(paiementsCotisationProvider(cotisationActive.id)).valueOrNull ??
            [];
    final totalDu = paiements.fold(0.0, (a, p) => a + p.montantDu);
    final totalCollecte = paiements.fold(0.0, (a, p) => a + p.montantPaye);
    final tauxRecouvrement =
        totalDu == 0 ? 0 : ((totalCollecte / totalDu) * 100).round();
    final nbPaye =
        paiements.where((p) => p.statut == StatutPaiement.paye).length;
    final nbPartiel =
        paiements.where((p) => p.statut == StatutPaiement.partiel).length;
    final nbImpaye = paiements
        .where((p) =>
            p.statut == StatutPaiement.impaye ||
            p.statut == StatutPaiement.enRetard)
        .length;
    final nbEnRetard =
        paiements.where((p) => p.statut == StatutPaiement.enRetard).length;

    final evenements = ref.watch(evenementsStreamProvider).valueOrNull ?? [];
    final evenementsActifs =
        evenements.where((e) => e.statut == StatutEvenement.actif).toList();

    final contributionsRecues =
        ref.watch(contributionsRecuesStreamProvider).valueOrNull ?? [];
    final contributionsPayees = contributionsRecues
        .where((c) => c.statut == StatutContribution.paye)
        .length;

    final membres = ref.watch(membresStreamProvider).valueOrNull ?? [];
    final membresParId = {for (final m in membres) m.id: m};

    final derniers = <_PaiementRecent>[];
    for (final p in paiements.where((p) => p.montantPaye > 0)) {
      final tranches = ref.watch(tranchesProvider(p.id)).valueOrNull ?? [];
      if (tranches.isEmpty) continue;
      final membre = membresParId[p.membreId];
      if (membre == null) continue;
      derniers.add(_PaiementRecent(
          membre: membre, montant: p.montantPaye, date: tranches.first.date));
    }
    derniers.sort((a, b) => b.date.compareTo(a.date));
    final derniersTop5 = derniers.take(5).toList();

    final entreesParMois = List<double>.filled(12, 0);
    final depensesParMois = List<double>.filled(12, 0);
    for (final r in recettes) {
      if (r.date.year == annee) entreesParMois[r.date.month - 1] += r.montant;
    }
    for (final d in depenses) {
      if (d.date.year == annee) {
        depensesParMois[d.date.month - 1] += d.montant;
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recettesStreamProvider);
        ref.invalidate(depensesStreamProvider);
        ref.invalidate(cotisationsStreamProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                titre: 'RECETTES',
                montant: totalRecettes,
                sousTitre: 'Cette année',
                couleurFond: AppColors.palme,
                couleurTexte: Colors.white,
                tonalite: Tonalite.palme,
              ),
              StatCard(
                titre: 'DÉPENSES',
                montant: totalDepenses,
                sousTitre: 'Cette année',
                couleurFond: AppColors.terre,
                couleurTexte: Colors.white,
                tonalite: Tonalite.terre,
              ),
              StatCard(
                titre: 'SOLDE',
                montant: solde,
                sousTitre: espace.nom,
                tonalite: Tonalite.indigo,
              ),
              _StatCompte(
                titre: 'ÉVÉNEMENTS ACTIFS',
                valeur: '${evenementsActifs.length}',
                tonalite: Tonalite.mixte,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Cotisation en cours',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (cotisationActive == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Aucune cotisation active pour le moment.',
                    style: TextStyle(color: AppColors.texteSecondaire)),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cotisationActive.nom,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (tauxRecouvrement / 100).clamp(0, 1),
                              minHeight: 8,
                              backgroundColor:
                                  AppColors.bordure.withValues(alpha: .4),
                              color: AppColors.palme,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('$tauxRecouvrement%',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                        '${formatMontant(totalCollecte)} collectés sur ${formatMontant(totalDu)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.texteSecondaire)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _BlocCompte(libelle: 'Payé', valeur: nbPaye)),
                        const SizedBox(width: 8),
                        Expanded(
                            child:
                                _BlocCompte(libelle: 'Partiel', valeur: nbPartiel)),
                        const SizedBox(width: 8),
                        Expanded(
                            child:
                                _BlocCompte(libelle: 'Impayé', valeur: nbImpaye)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _StatCompte(
                titre: 'MEMBRES EN RETARD',
                valeur: '$nbEnRetard',
                tonalite: Tonalite.terre,
              ),
              _StatCompte(
                titre: 'CONTRIBUTIONS DEMANDÉES',
                valeur: '${contributionsRecues.length}',
                sousTitre: '$contributionsPayees réglée(s)',
                tonalite: Tonalite.or,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (evenementsActifs.isNotEmpty) ...[
            Text('Événements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  for (final e in evenementsActifs) ...[
                    if (e != evenementsActifs.first) const Divider(height: 1),
                    ListTile(
                      title: Text(e.nom),
                      subtitle: e.montantCible == null
                          ? null
                          : Text(
                              '${formatMontant(e.montantCollecte)} / ${formatMontant(e.montantCible!)}'),
                      trailing: e.progression == null
                          ? null
                          : Text(
                              '${(e.progression! * 100).clamp(0, 100).round()}%'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (contributionsRecues.isNotEmpty) ...[
            Text('Contributions demandées par l\'église',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  for (final c in contributionsRecues) ...[
                    if (c != contributionsRecues.first)
                      const Divider(height: 1),
                    ListTile(
                      title: Text(c.projet),
                      subtitle: Text(
                          '${formatMontant(c.montantRecu)} / ${formatMontant(c.montantDemande)}'),
                      trailing: Chip(
                        label: Text(c.statut.libelle),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (derniersTop5.isNotEmpty) ...[
            Text('Derniers paiements',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  for (final p in derniersTop5) ...[
                    if (p != derniersTop5.first) const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.indigoProfond,
                        child: Text(
                          p.membre.nomComplet.isNotEmpty
                              ? p.membre.nomComplet[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(p.membre.nomComplet),
                      trailing: Text(formatMontant(p.montant),
                          style: const TextStyle(color: AppColors.palme)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text('Recettes / Dépenses $annee',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: _GraphiqueMensuel(
                entrees: entreesParMois, depenses: depensesParMois),
          ),
        ],
      ),
    );
  }
}

class _PaiementRecent {
  final Membre membre;
  final double montant;
  final DateTime date;
  _PaiementRecent(
      {required this.membre, required this.montant, required this.date});
}

class _BlocCompte extends StatelessWidget {
  final String libelle;
  final int valeur;

  const _BlocCompte({required this.libelle, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fond,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text('$valeur',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          Text(libelle,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.texteSecondaire)),
        ],
      ),
    );
  }
}

class _StatCompte extends StatelessWidget {
  final String titre;
  final String valeur;
  final String? sousTitre;
  final Tonalite tonalite;

  const _StatCompte({
    required this.titre,
    required this.valeur,
    this.sousTitre,
    this.tonalite = Tonalite.or,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BandeTissee(tonalite: tonalite),
          const SizedBox(height: 10),
          Text(
            titre,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .5,
              color: AppColors.texteSecondaire,
            ),
          ),
          const SizedBox(height: 8),
          Text(valeur,
              style: AppFonts.montant(
                  fontSize: 20, color: AppColors.texteEncre)),
          if (sousTitre != null) ...[
            const SizedBox(height: 4),
            Text(sousTitre!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.texteSecondaire)),
          ],
        ],
      ),
    );
  }
}

class _GraphiqueMensuel extends StatelessWidget {
  final List<double> entrees;
  final List<double> depenses;

  const _GraphiqueMensuel({required this.entrees, required this.depenses});

  @override
  Widget build(BuildContext context) {
    final maxY = [...entrees, ...depenses].fold(0.0, (a, b) => b > a ? b : a);
    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 10 : maxY * 1.2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(formatMoisCourt(value.toInt()),
                    style: const TextStyle(fontSize: 10)),
              ),
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(12, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                  toY: entrees[i], color: AppColors.palme, width: 6),
              BarChartRodData(
                  toY: depenses[i], color: AppColors.terre, width: 6),
            ],
          );
        }),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
