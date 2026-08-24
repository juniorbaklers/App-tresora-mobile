import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/membre.dart';
import '../../providers/data_providers.dart';
import '../../widgets/role_gate.dart';
import 'membre_form_screen.dart';

class MembresListScreen extends ConsumerWidget {
  const MembresListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membresAsync = ref.watch(membresStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Membres')),
      floatingActionButton: RoleGate(
        peutAcceder: (r) => r.peutSaisir,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MembreFormScreen()),
          ),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Nouveau'),
        ),
      ),
      body: membresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur : $e')),
        data: (membres) {
          if (membres.isEmpty) return const Center(child: Text('Aucun membre enregistré'));
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: membres.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) => _MembreTile(membre: membres[i]),
          );
        },
      ),
    );
  }
}

class _MembreTile extends ConsumerWidget {
  final Membre membre;

  const _MembreTile({required this.membre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: membre.actif ? Colors.green.withValues(alpha: .12) : Colors.grey.withValues(alpha: .15),
          child: Icon(Icons.person, color: membre.actif ? Colors.green[700] : Colors.grey),
        ),
        title: Text(membre.nomComplet, style: TextStyle(color: membre.actif ? null : Colors.grey)),
        subtitle: Text(membre.telephone?.isNotEmpty == true ? membre.telephone! : 'Pas de téléphone'),
        trailing: RoleGate(
          peutAcceder: (r) => r.peutSaisir,
          child: Switch(
            value: membre.actif,
            onChanged: (v) => ref.read(membresServiceProvider).modifier(membre.id, {'actif': v}),
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MembreFormScreen(membre: membre)),
        ),
      ),
    );
  }
}
