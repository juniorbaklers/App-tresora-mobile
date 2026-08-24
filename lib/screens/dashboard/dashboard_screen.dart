import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/tresorerie.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caissesAsync = ref.watch(caissesStreamProvider);
    final mouvementsAsync = ref.watch(mouvementsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: caissesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (caisses) => mouvementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (mouvements) {
            final annee = DateTime.now().year;
            final totalEntrees = Tresorerie.totalEntreesCaisseGenerale(caisses, mouvements);
            final totalDepenses = Tresorerie.totalDepensesCaisseGenerale(mouvements);
            final solde = totalEntrees - totalDepenses;
            final parMois = Tresorerie.parMoisCaisseGenerale(caisses, mouvements, annee);
            final caissesSeparees = caisses.where((c) => !c.incluseCaisseGenerale).toList();

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(caissesStreamProvider);
                ref.invalidate(mouvementsStreamProvider);
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
                        titre: 'TOTAL ENTRÉES',
                        montant: totalEntrees,
                        sousTitre: 'Caisse générale',
                        couleurFond: AppColors.vert,
                        couleurTexte: Colors.white,
                      ),
                      StatCard(
                        titre: 'TOTAL DÉPENSES',
                        montant: totalDepenses,
                        sousTitre: 'Caisse générale',
                        couleurFond: AppColors.rouge,
                        couleurTexte: Colors.white,
                      ),
                      StatCard(
                        titre: 'SOLDE GLOBAL',
                        montant: solde,
                        sousTitre: 'Caisse générale',
                      ),
                      if (caissesSeparees.isNotEmpty)
                        StatCard(
                          titre: caissesSeparees.first.nom.toUpperCase(),
                          montant: Tresorerie.soldeCaisse(caissesSeparees.first.id, mouvements),
                          sousTitre: 'Caisse séparée',
                          couleurFond: AppColors.or,
                          couleurTexte: Colors.white,
                        ),
                    ],
                  ),
                  if (caissesSeparees.length > 1) ...[
                    const SizedBox(height: 12),
                    ...caissesSeparees.skip(1).map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: StatCard(
                              titre: c.nom.toUpperCase(),
                              montant: Tresorerie.soldeCaisse(c.id, mouvements),
                              sousTitre: 'Caisse séparée',
                              couleurFond: AppColors.or,
                              couleurTexte: Colors.white,
                            ),
                          ),
                        ),
                  ],
                  const SizedBox(height: 24),
                  Text('Entrées / Dépenses $annee', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 260,
                    child: _GraphiqueMensuel(entrees: parMois.entrees, depenses: parMois.depenses),
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
              BarChartRodData(toY: entrees[i], color: AppColors.vert, width: 6),
              BarChartRodData(toY: depenses[i], color: AppColors.rouge, width: 6),
            ],
          );
        }),
      ),
    );
  }
}
