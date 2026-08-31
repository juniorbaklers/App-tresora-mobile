import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/tresorerie.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import '../rapports/rapport_screen.dart';
import 'tresorerie_form_screen.dart';
import '../../utils/erreurs.dart';

sealed class _Ligne {
  DateTime get date;
}

class _LigneRecette extends _Ligne {
  final Recette recette;
  _LigneRecette(this.recette);
  @override
  DateTime get date => recette.date;
}

class _LigneDepense extends _Ligne {
  final Depense depense;
  _LigneDepense(this.depense);
  @override
  DateTime get date => depense.date;
}

/// Liste des écritures (recettes + dépenses) — habillage refait d'après la
/// maquette « Écritures » du canvas de design : cartes de synthèse
/// recettes/dépenses en tête, entrées groupées par jour. La récupération et
/// le tri des données sont inchangés ; le groupage par jour et les totaux
/// sont une présentation de ce qui était déjà chargé, pas une nouvelle
/// requête.
class TresorerieListScreen extends ConsumerWidget {
  const TresorerieListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recettesAsync = ref.watch(recettesStreamProvider);
    final depensesAsync = ref.watch(depensesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Écritures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Rapport',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RapportScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: RoleGate(
        peutAcceder: (r) => r.peutGerer,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TresorerieFormScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nouveau'),
        ),
      ),
      body: recettesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
        data: (recettes) => depensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
          data: (depenses) {
            final lignes = <_Ligne>[
              ...recettes.map(_LigneRecette.new),
              ...depenses.map(_LigneDepense.new),
            ]..sort((a, b) => b.date.compareTo(a.date));

            if (lignes.isEmpty) {
              return const Center(child: Text('Aucune écriture'));
            }

            final totalRecettes = recettes.fold(0.0, (a, r) => a + r.montant);
            final totalDepenses = depenses.fold(0.0, (a, d) => a + d.montant);

            final groupes = <DateTime, List<_Ligne>>{};
            for (final l in lignes) {
              final jour = DateTime(l.date.year, l.date.month, l.date.day);
              groupes.putIfAbsent(jour, () => []).add(l);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CarteSynthese(
                          libelle: 'Recettes',
                          montant: totalRecettes,
                          couleur: AppColors.palme),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _CarteSynthese(
                          libelle: 'Dépenses',
                          montant: totalDepenses,
                          couleur: AppColors.terre),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                for (final jour in groupes.keys) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(_libelleJour(jour),
                        style: AppFonts.eyebrow(
                            color: AppColors.texteSecondaire)),
                  ),
                  for (final ligne in groupes[jour]!) ...[
                    _LigneTile(ligne: ligne),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

String _libelleJour(DateTime jour) {
  final aujourdhui = DateTime.now();
  final j = DateTime(aujourdhui.year, aujourdhui.month, aujourdhui.day);
  if (jour == j) return "AUJOURD'HUI";
  if (jour == j.subtract(const Duration(days: 1))) return 'HIER';
  return DateFormat('d MMMM', 'fr_FR').format(jour).toUpperCase();
}

class _CarteSynthese extends StatelessWidget {
  final String libelle;
  final double montant;
  final Color couleur;

  const _CarteSynthese(
      {required this.libelle, required this.montant, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(libelle,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.texteSecondaire)),
          const SizedBox(height: 2),
          Text(formatMontant(montant),
              style: AppFonts.montant(fontSize: 16, color: couleur)),
        ],
      ),
    );
  }
}

class _LigneTile extends StatelessWidget {
  final _Ligne ligne;

  const _LigneTile({required this.ligne});

  @override
  Widget build(BuildContext context) {
    final estRecette = ligne is _LigneRecette;
    final couleur = estRecette ? AppColors.palme : AppColors.terre;
    final montant = switch (ligne) {
      _LigneRecette(:final recette) => recette.montant,
      _LigneDepense(:final depense) => depense.montant,
    };
    final titre = switch (ligne) {
      _LigneRecette(:final recette) =>
        recette.libelle.isEmpty ? recette.categorie.libelle : recette.libelle,
      _LigneDepense(:final depense) =>
        depense.description.isEmpty ? depense.categorie : depense.description,
    };
    final sousTitre = switch (ligne) {
      _LigneRecette(:final recette) => recette.categorie.libelle,
      _LigneDepense(:final depense) =>
        depense.beneficiaire.isEmpty ? depense.categorie : depense.beneficiaire,
    };

    return Container(
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
              color: couleur.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(estRecette ? Icons.arrow_downward : Icons.arrow_upward,
                color: couleur, size: 16),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texteEncre)),
                Text(sousTitre,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.texteSecondaire)),
              ],
            ),
          ),
          Text(
            '${estRecette ? '+' : '−'}${formatMontant(montant)}',
            style: AppFonts.montant(
                fontSize: 13,
                color: estRecette ? AppColors.palme : AppColors.texteEncre),
          ),
        ],
      ),
    );
  }
}
