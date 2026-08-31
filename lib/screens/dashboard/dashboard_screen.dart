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
import '../rapports/rapport_screen.dart';
import '../tresorerie/tresorerie_form_screen.dart';
import '../../utils/erreurs.dart';

/// Tableau de bord : l'écran s'adapte au type d'espace, comme tresora-app
/// (src/app/espace/[espaceId]/dashboard/page.tsx) qui choisit entre
/// `DashboardEglise` et `DashboardGroupe` selon `espace.type === "eglise"`.
///
/// Habillage refait d'après la maquette « Accueil de l'espace » du canvas de
/// design (carte solde sombre texturée + tendance, rangée d'actions rapides,
/// dernières écritures) — la logique de calcul en dessous est inchangée.
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
              backgroundColor: AppColors.alerte,
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
      error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
      data: (recettes) => depensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
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

          final ecritures = _fusionnerEcritures(recettes, depenses);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recettesStreamProvider);
              ref.invalidate(depensesStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CarteSolde(
                  nomEspace: espace?.nom ?? 'Trésora',
                  solde: solde,
                  totalRecettes: totalRecettes,
                  totalDepenses: totalDepenses,
                  tendance: entreesParMois,
                ),
                const SizedBox(height: 14),
                const _ActionsRapides(),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
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
                if (afficherDimes || afficherOffrandes)
                  const SizedBox(height: 24),
                if (ecritures.isNotEmpty) ...[
                  _EnTeteSection(
                    titre: 'Dernières écritures',
                    action: 'Tout voir',
                    onAction: () {},
                  ),
                  const SizedBox(height: 12),
                  _ListeEcritures(ecritures: ecritures.take(5).toList()),
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
      error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
      data: (recettes) => depensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
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
    if (cotisationActive != null) {
      final toutesTranches = ref
              .watch(tranchesCotisationProvider(cotisationActive.id))
              .valueOrNull ??
          [];
      final derniereDateParPaiement = <String, DateTime>{};
      for (final t in toutesTranches) {
        final actuelle = derniereDateParPaiement[t.paiementCotisationId];
        if (actuelle == null || t.date.isAfter(actuelle)) {
          derniereDateParPaiement[t.paiementCotisationId] = t.date;
        }
      }
      for (final p in paiements.where((p) => p.montantPaye > 0)) {
        final date = derniereDateParPaiement[p.id];
        if (date == null) continue;
        final membre = membresParId[p.membreId];
        if (membre == null) continue;
        derniers.add(
            _PaiementRecent(membre: membre, montant: p.montantPaye, date: date));
      }
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
          _CarteSolde(
            nomEspace: espace.nom,
            solde: solde,
            totalRecettes: totalRecettes,
            totalDepenses: totalDepenses,
            tendance: entreesParMois,
          ),
          const SizedBox(height: 14),
          const _ActionsRapides(),
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
                titre: 'ÉVÉNEMENTS ACTIFS',
                valeur: '${evenementsActifs.length}',
                tonalite: Tonalite.mixte,
              ),
              _StatCompte(
                titre: 'MEMBRES EN RETARD',
                valeur: '$nbEnRetard',
                tonalite: Tonalite.terre,
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
          _StatCompte(
            titre: 'CONTRIBUTIONS DEMANDÉES',
            valeur: '${contributionsRecues.length}',
            sousTitre: '$contributionsPayees réglée(s)',
            tonalite: Tonalite.or,
          ),
          const SizedBox(height: 24),
          if (evenementsActifs.isNotEmpty) ...[
            Text('Événements', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final e in evenementsActifs) ...[
              _LigneDashboard(
                titre: e.nom,
                sousTitre: e.montantCible == null
                    ? null
                    : '${formatMontant(e.montantCollecte)} / ${formatMontant(e.montantCible!)}',
                trailing: e.progression == null
                    ? null
                    : Text(
                        '${(e.progression! * 100).clamp(0, 100).round()}%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.texteEncre)),
              ),
              if (e != evenementsActifs.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 24),
          ],
          if (contributionsRecues.isNotEmpty) ...[
            Text('Contributions demandées par l\'église',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final c in contributionsRecues) ...[
              _LigneDashboard(
                titre: c.projet,
                sousTitre:
                    '${formatMontant(c.montantRecu)} / ${formatMontant(c.montantDemande)}',
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.or.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(c.statut.libelle,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.or)),
                ),
              ),
              if (c != contributionsRecues.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 24),
          ],
          if (derniersTop5.isNotEmpty) ...[
            Text('Derniers paiements',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final p in derniersTop5) ...[
              _LigneDashboard(
                initiales: p.membre.nomComplet.isNotEmpty
                    ? p.membre.nomComplet[0].toUpperCase()
                    : '?',
                titre: p.membre.nomComplet,
                trailing: Text(formatMontant(p.montant),
                    style: AppFonts.montant(
                        fontSize: 13, color: AppColors.palme)),
              ),
              if (p != derniersTop5.last) const SizedBox(height: 8),
            ],
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

/// Carte hero du tableau de bord — fond graphite texturé, libellé « SOLDE »
/// en mono, montant en Schibsted Grotesk avec chiffres tabulaires, tendance
/// de l'année en mini-courbe, recettes/dépenses en aperçu inline. Reprend la
/// carte de la maquette « Accueil de l'espace ».
class _CarteSolde extends StatelessWidget {
  final String nomEspace;
  final double solde;
  final double totalRecettes;
  final double totalDepenses;
  final List<double> tendance;

  const _CarteSolde({
    required this.nomEspace,
    required this.solde,
    required this.totalRecettes,
    required this.totalDepenses,
    required this.tendance,
  });

  static const _mois = [
    'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
    'jul', 'aoû', 'sep', 'oct', 'nov', 'déc',
  ];

  @override
  Widget build(BuildContext context) {
    final maintenant = DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.graphite,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.terre,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      nomEspace.isNotEmpty ? nomEspace[0].toUpperCase() : 'T',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(nomEspace,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
              Text('${_mois[maintenant.month - 1]} ${maintenant.year}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: .55),
                      fontSize: 10)),
            ],
          ),
          const SizedBox(height: 16),
          Text('SOLDE',
              style: AppFonts.eyebrow(color: Colors.white.withValues(alpha: .55))),
          const SizedBox(height: 4),
          Text(formatMontant(solde),
              style: AppFonts.montant(fontSize: 28, color: Colors.white)),
          SizedBox(
            height: 44,
            child: _MiniCourbe(valeurs: tendance),
          ),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                    label: 'Recettes',
                    valeur: totalRecettes,
                    couleur: AppColors.orSurSombre),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                    label: 'Dépenses',
                    valeur: totalDepenses,
                    couleur: AppColors.terreSurSombre),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double valeur;
  final Color couleur;

  const _MiniStat(
      {required this.label, required this.valeur, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: .55), fontSize: 10)),
          Text(formatMontant(valeur),
              style: TextStyle(
                  color: couleur, fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _MiniCourbe extends StatelessWidget {
  final List<double> valeurs;

  const _MiniCourbe({required this.valeurs});

  @override
  Widget build(BuildContext context) {
    final points = <FlSpot>[
      for (var i = 0; i < valeurs.length; i++) FlSpot(i.toDouble(), valeurs[i])
    ];
    final maxY = valeurs.fold(0.0, (a, b) => b > a ? b : a);
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY == 0 ? 10 : maxY * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            barWidth: 2.5,
            color: AppColors.terre,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}

/// Rangée d'actions rapides — encaisser / dépense / rapport, comme la
/// maquette « Accueil de l'espace ».
class _ActionsRapides extends StatelessWidget {
  const _ActionsRapides();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionRapide(
            icone: Icons.south_west_rounded,
            libelle: 'Encaisser',
            couleur: AppColors.terre,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TresorerieFormScreen()),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ActionRapide(
            icone: Icons.north_east_rounded,
            libelle: 'Dépense',
            couleur: AppColors.alerte,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TresorerieFormScreen()),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _ActionRapide(
            icone: Icons.description_outlined,
            libelle: 'Rapport',
            couleur: AppColors.or,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RapportScreen()),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionRapide extends StatelessWidget {
  final IconData icone;
  final String libelle;
  final Color couleur;
  final VoidCallback onTap;

  const _ActionRapide({
    required this.icone,
    required this.libelle,
    required this.couleur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.carte,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bordure),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icone, size: 16, color: couleur),
              ),
              const SizedBox(height: 7),
              Text(libelle,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.texteEncre)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnTeteSection extends StatelessWidget {
  final String titre;
  final String? action;
  final VoidCallback? onAction;

  const _EnTeteSection({required this.titre, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(titre, style: Theme.of(context).textTheme.titleMedium),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.terre)),
          ),
      ],
    );
  }
}

class _Ecriture {
  final IconData icone;
  final Color couleur;
  final String titre;
  final String sousTitre;
  final double montant;
  final bool positif;

  const _Ecriture({
    required this.icone,
    required this.couleur,
    required this.titre,
    required this.sousTitre,
    required this.montant,
    required this.positif,
  });
}

List<_Ecriture> _fusionnerEcritures(
    List<Recette> recettes, List<Depense> depenses) {
  return <_Ecriture>[
    for (final r in recettes)
      _Ecriture(
        icone: Icons.volunteer_activism_outlined,
        couleur: AppColors.palme,
        titre: r.libelle.isNotEmpty ? r.libelle : r.categorie.libelle,
        sousTitre: _sousTitreDate(r.date),
        montant: r.montant,
        positif: true,
      ),
    for (final d in depenses)
      _Ecriture(
        icone: Icons.arrow_outward_rounded,
        couleur: AppColors.terre,
        titre: d.description.isNotEmpty ? d.description : d.categorie,
        sousTitre: '${d.modePaiement.libelle} · ${_sousTitreDate(d.date)}',
        montant: d.montant,
        positif: false,
      ),
  ];
}

String _sousTitreDate(DateTime date) {
  final aujourdhui = DateTime.now();
  final estAujourdhui = date.year == aujourdhui.year &&
      date.month == aujourdhui.month &&
      date.day == aujourdhui.day;
  if (estAujourdhui) return "aujourd'hui";
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

class _ListeEcritures extends StatelessWidget {
  final List<_Ecriture> ecritures;

  const _ListeEcritures({required this.ecritures});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final e in ecritures) ...[
          if (e != ecritures.first) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.carte,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: e.couleur.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(e.icone, size: 16, color: e.couleur),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.titre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.texteEncre)),
                      Text(e.sousTitre,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.texteSecondaire)),
                    ],
                  ),
                ),
                Text(
                  '${e.positif ? '+' : '−'}${formatMontant(e.montant)}',
                  style: AppFonts.montant(
                      fontSize: 13,
                      color: e.positif
                          ? AppColors.palme
                          : AppColors.texteEncre),
                ),
              ],
            ),
          ),
        ],
      ],
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

/// Ligne de liste plate bordée — carte à part par élément, cohérente avec le
/// pattern déjà utilisé sur les autres écrans refaits (tresorerie_list,
/// cotisation_detail, evenement_detail) plutôt qu'un `Card`+`ListTile` par
/// défaut avec `Divider` interne.
class _LigneDashboard extends StatelessWidget {
  final String? initiales;
  final String titre;
  final String? sousTitre;
  final Widget? trailing;

  const _LigneDashboard({
    this.initiales,
    required this.titre,
    this.sousTitre,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Row(
        children: [
          if (initiales != null) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.graphite,
              child: Text(initiales!,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: AppFonts.heading(
                        fontSize: 13, color: AppColors.texteEncre)),
                if (sousTitre != null) ...[
                  const SizedBox(height: 3),
                  Text(sousTitre!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.texteSecondaire)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
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
