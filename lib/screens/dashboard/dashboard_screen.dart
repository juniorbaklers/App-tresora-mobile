import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/motif.dart';
import '../../widgets/stat_card.dart';
import '../contributions/contributions_list_screen.dart';
import '../notifications/notifications_list_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espace = ref.watch(currentEspaceProvider)?.espace;
    final recettesAsync = ref.watch(recettesStreamProvider);
    final depensesAsync = ref.watch(depensesStreamProvider);
    final notificationsNonLues =
        (ref.watch(mesNotificationsProvider).valueOrNull ?? []).where((n) => !n.lue).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(espace?.nom ?? 'Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Contributions inter-espaces',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ContributionsListScreen()),
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
              MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
            ),
          ),
        ],
      ),
      body: recettesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (recettes) => depensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (depenses) {
            final annee = DateTime.now().year;
            final totalRecettes = recettes.fold(0.0, (a, r) => a + r.montant);
            final totalDepenses = depenses.fold(0.0, (a, d) => a + d.montant);
            final solde = (espace?.soldeInitial ?? 0) + totalRecettes - totalDepenses;

            final entreesParMois = List<double>.filled(12, 0);
            final depensesParMois = List<double>.filled(12, 0);
            for (final r in recettes) {
              if (r.date.year == annee) entreesParMois[r.date.month - 1] += r.montant;
            }
            for (final d in depenses) {
              if (d.date.year == annee) depensesParMois[d.date.month - 1] += d.montant;
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Recettes / Dépenses $annee', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: _GraphiqueMensuel(entrees: entreesParMois, depenses: depensesParMois),
                  ),
                ],
              ),
            );
          },
        ),
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
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(formatMoisCourt(value.toInt()), style: const TextStyle(fontSize: 10)),
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
              BarChartRodData(toY: entrees[i], color: AppColors.palme, width: 6),
              BarChartRodData(toY: depenses[i], color: AppColors.terre, width: 6),
            ],
          );
        }),
      ),
    );
  }
}
