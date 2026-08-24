import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/caisse.dart';
import '../../models/mouvement.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import 'mouvement_form_screen.dart';

class MouvementsListScreen extends ConsumerStatefulWidget {
  const MouvementsListScreen({super.key});

  @override
  ConsumerState<MouvementsListScreen> createState() => _MouvementsListScreenState();
}

class _MouvementsListScreenState extends ConsumerState<MouvementsListScreen> {
  TypeMouvement? _filtreType;
  String? _filtreCaisseId;

  @override
  Widget build(BuildContext context) {
    final mouvementsAsync = ref.watch(mouvementsStreamProvider);
    final caissesAsync = ref.watch(caissesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mouvements')),
      floatingActionButton: RoleGate(
        peutAcceder: (r) => r.peutSaisir,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MouvementFormScreen()),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nouveau'),
        ),
      ),
      body: caissesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (caisses) {
          final caissesParId = {for (final c in caisses) c.id: c};
          return Column(
            children: [
              _BarreFiltres(
                caisses: caisses,
                filtreType: _filtreType,
                filtreCaisseId: _filtreCaisseId,
                onTypeChange: (v) => setState(() => _filtreType = v),
                onCaisseChange: (v) => setState(() => _filtreCaisseId = v),
              ),
              Expanded(
                child: mouvementsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Erreur : $e')),
                  data: (mouvements) {
                    var liste = mouvements;
                    if (_filtreType != null) {
                      liste = liste.where((m) => m.type == _filtreType).toList();
                    }
                    if (_filtreCaisseId != null) {
                      liste = liste.where((m) => m.caisseId == _filtreCaisseId).toList();
                    }
                    if (liste.isEmpty) {
                      return const Center(child: Text('Aucun mouvement'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: liste.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final m = liste[i];
                        final caisse = m.caisseId == null ? null : caissesParId[m.caisseId];
                        return _MouvementTile(mouvement: m, nomCaisse: caisse?.nom ?? 'Caisse Générale');
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BarreFiltres extends StatelessWidget {
  final List<Caisse> caisses;
  final TypeMouvement? filtreType;
  final String? filtreCaisseId;
  final ValueChanged<TypeMouvement?> onTypeChange;
  final ValueChanged<String?> onCaisseChange;

  const _BarreFiltres({
    required this.caisses,
    required this.filtreType,
    required this.filtreCaisseId,
    required this.onTypeChange,
    required this.onCaisseChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<TypeMouvement?>(
              initialValue: filtreType,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Type', isDense: true),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tous types')),
                DropdownMenuItem(value: TypeMouvement.entree, child: Text('Entrées')),
                DropdownMenuItem(value: TypeMouvement.depense, child: Text('Dépenses')),
              ],
              onChanged: onTypeChange,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String?>(
              initialValue: filtreCaisseId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Caisse', isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('Toutes caisses')),
                ...caisses.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: onCaisseChange,
            ),
          ),
        ],
      ),
    );
  }
}

class _MouvementTile extends StatelessWidget {
  final Mouvement mouvement;
  final String nomCaisse;

  const _MouvementTile({required this.mouvement, required this.nomCaisse});

  @override
  Widget build(BuildContext context) {
    final estEntree = mouvement.type == TypeMouvement.entree;
    final couleur = estEntree ? AppColors.vert : AppColors.rouge;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: couleur.withValues(alpha: .12),
          child: Icon(estEntree ? Icons.arrow_downward : Icons.arrow_upward, color: couleur, size: 20),
        ),
        title: Text(mouvement.nomLibre ?? mouvement.motif ?? nomCaisse),
        subtitle: Text(
          '$nomCaisse • ${formatDate(mouvement.date)}'
          '${mouvement.numeroRecu != null ? ' • ${mouvement.numeroRecu}' : ''}',
        ),
        trailing: Text(
          '${estEntree ? '+' : '-'} ${formatMontant(mouvement.montant)}',
          style: TextStyle(color: couleur, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
