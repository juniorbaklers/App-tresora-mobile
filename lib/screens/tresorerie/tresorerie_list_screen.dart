import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tresorerie.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import 'tresorerie_form_screen.dart';

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

class TresorerieListScreen extends ConsumerWidget {
  const TresorerieListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recettesAsync = ref.watch(recettesStreamProvider);
    final depensesAsync = ref.watch(depensesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Recettes & Dépenses')),
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
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (recettes) => depensesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur : $e')),
          data: (depenses) {
            final lignes = <_Ligne>[
              ...recettes.map(_LigneRecette.new),
              ...depenses.map(_LigneDepense.new),
            ]..sort((a, b) => b.date.compareTo(a.date));

            if (lignes.isEmpty) return const Center(child: Text('Aucune écriture'));

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: lignes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _LigneTile(ligne: lignes[i]),
            );
          },
        ),
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
      _LigneRecette(:final recette) => recette.libelle.isEmpty ? recette.categorie.libelle : recette.libelle,
      _LigneDepense(:final depense) => depense.description.isEmpty ? depense.categorie : depense.description,
    };
    final sousTitre = switch (ligne) {
      _LigneRecette(:final recette) => recette.categorie.libelle,
      _LigneDepense(:final depense) => depense.beneficiaire.isEmpty ? depense.categorie : depense.beneficiaire,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: .12),
          child: Icon(estRecette ? Icons.arrow_downward : Icons.arrow_upward, color: couleur, size: 20),
        ),
        title: Text(titre),
        subtitle: Text('$sousTitre • ${formatDate(ligne.date)}'),
        trailing: Text(
          '${estRecette ? '+' : '-'} ${formatMontant(montant)}',
          style: TextStyle(color: couleur, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
