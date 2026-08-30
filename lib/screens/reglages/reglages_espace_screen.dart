import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/espace.dart';
import '../../models/membre_compte.dart';
import '../../models/module_espace.dart';
import '../../models/role.dart';
import '../../providers/auth_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../clotures/clotures_list_screen.dart';
import '../journal/journal_list_screen.dart';
import 'roles_permissions_screen.dart';

class ReglagesEspaceScreen extends ConsumerWidget {
  const ReglagesEspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espaceAvecRole = ref.watch(currentEspaceProvider);
    final espace = espaceAvecRole?.espace;
    final membresCompte =
        ref.watch(membresCompteStreamProvider).valueOrNull ?? [];
    final userId = ref.watch(currentUserProvider)?.id;

    if (espace == null) return const Scaffold(body: SizedBox.shrink());

    final afficherClotures = espace.aModule(ModuleEspace.dimes) ||
        espace.aModule(ModuleEspace.offrandes);

    return Scaffold(
      appBar: AppBar(title: const Text('Réglages de l\'espace')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('ESPACE',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.texteSecondaire,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.carte,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(espace.nom,
                          style: AppFonts.heading(
                              fontSize: 16, color: AppColors.texteEncre)),
                      const SizedBox(height: 3),
                      Text(
                          '${espace.type.libelle} · ${espace.devise} · solde initial ${formatMontant(espace.soldeInitial)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.texteSecondaire)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      _ouvrirFormulaireModification(context, espace),
                  child: const Text('Modifier'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('MODULES',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.texteSecondaire,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            'Choisis les fonctionnalités actives sur cet espace — modifiable à tout moment.',
            style: TextStyle(fontSize: 12, color: AppColors.texteSecondaire),
          ),
          const SizedBox(height: 8),
          _SectionModules(espace: espace),
          const SizedBox(height: 24),
          Text('OUTILS',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.texteSecondaire,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.carte,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bordure),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _LigneOutil(
                  icone: Icons.history,
                  titre: 'Journal d\'audit',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const JournalListScreen()),
                  ),
                ),
                if (afficherClotures) ...[
                  const Divider(height: 1, color: AppColors.bordure),
                  _LigneOutil(
                    icone: Icons.fact_check_outlined,
                    titre: 'Clôtures',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CloturesListScreen()),
                    ),
                  ),
                ],
                const Divider(height: 1, color: AppColors.bordure),
                _LigneOutil(
                  icone: Icons.shield_outlined,
                  titre: 'Rôles et permissions',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const RolesPermissionsScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('MEMBRES ET RÔLES',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.texteSecondaire,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (membresCompte.isEmpty)
            const Text('Aucun compte pour l\'instant',
                style: TextStyle(color: AppColors.texteSecondaire))
          else
            for (final mc in membresCompte)
              _MembreCompteTile(
                  membreCompte: mc, estMoi: mc.profil.id == userId),
        ],
      ),
    );
  }

  void _ouvrirFormulaireModification(BuildContext context, Espace espace) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FormulaireEspace(espace: espace),
    );
  }
}

class _LigneOutil extends StatelessWidget {
  final IconData icone;
  final String titre;
  final VoidCallback onTap;

  const _LigneOutil(
      {required this.icone, required this.titre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.carte,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icone, size: 20, color: AppColors.texteSecondaire),
              const SizedBox(width: 14),
              Expanded(
                child: Text(titre,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.texteEncre)),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.texteSecondaire, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionModules extends ConsumerWidget {
  final Espace espace;

  const _SectionModules({required this.espace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espaceCourant = ref.watch(currentEspaceProvider)?.espace ?? espace;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final module in ModuleEspace.values) ...[
            if (module != ModuleEspace.values.first)
              const Divider(height: 1, color: AppColors.bordure),
            CheckboxListTile(
              value: espaceCourant.aModule(module),
              title: Text(module.libelle),
              subtitle:
                  module.estObligatoire ? const Text('Toujours actif') : null,
              onChanged: module.estObligatoire
                  ? null
                  : (coche) {
                      final nouveauxModules = [...espaceCourant.modules];
                      if (coche == true) {
                        nouveauxModules.add(module);
                      } else {
                        nouveauxModules.remove(module);
                      }
                      ref
                          .read(espacesServiceProvider)
                          .definirModules(espaceCourant.id, nouveauxModules);
                    },
            ),
          ],
        ],
      ),
    );
  }
}

class _MembreCompteTile extends ConsumerWidget {
  final MembreCompte membreCompte;
  final bool estMoi;

  const _MembreCompteTile({required this.membreCompte, required this.estMoi});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espaceId = ref.watch(currentEspaceIdProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.graphite,
              shape: BoxShape.circle,
            ),
            child: Text(
              (membreCompte.profil.nomComplet.isNotEmpty
                      ? membreCompte.profil.nomComplet[0]
                      : '?')
                  .toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    membreCompte.profil.nomComplet +
                        (estMoi ? ' (toi)' : ''),
                    style: AppFonts.heading(
                        fontSize: 13, color: AppColors.texteEncre)),
                const SizedBox(height: 3),
                Text(membreCompte.profil.email,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.texteSecondaire)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          membreCompte.role == RoleEspace.proprietaire
              ? _BadgeRole(libelle: 'Propriétaire')
              : PopupMenuButton<Object>(
                  child: _BadgeRole(libelle: membreCompte.role.libelle),
                  itemBuilder: (_) => [
                    for (final r in RoleEspace.values
                        .where((r) => r != RoleEspace.proprietaire))
                      PopupMenuItem(value: r, child: Text(r.libelle)),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                        value: 'retirer', child: Text('Retirer de l\'espace')),
                  ],
                  onSelected: (valeur) {
                    if (espaceId == null) return;
                    if (valeur == 'retirer') {
                      ref
                          .read(espacesServiceProvider)
                          .retirerMembre(espaceId, membreCompte.profil.id);
                    } else if (valeur is RoleEspace) {
                      ref.read(espacesServiceProvider).changerRole(
                          espaceId, membreCompte.profil.id, valeur);
                    }
                  },
                ),
        ],
      ),
    );
  }
}

class _BadgeRole extends StatelessWidget {
  final String libelle;

  const _BadgeRole({required this.libelle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.fond,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Text(libelle,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.texteSecondaire)),
    );
  }
}

class _FormulaireEspace extends ConsumerStatefulWidget {
  final Espace espace;

  const _FormulaireEspace({required this.espace});

  @override
  ConsumerState<_FormulaireEspace> createState() => _FormulaireEspaceState();
}

class _FormulaireEspaceState extends ConsumerState<_FormulaireEspace> {
  final _formKey = GlobalKey<FormState>();
  late final _nomCtrl = TextEditingController(text: widget.espace.nom);
  late final _soldeCtrl = TextEditingController(
      text: widget.espace.soldeInitial.toStringAsFixed(0));
  late String _devise = widget.espace.devise;
  bool _enCours = false;
  String? _erreur;

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(espacesServiceProvider).modifier(widget.espace.id, {
        'nom': _nomCtrl.text.trim(),
        'devise': _devise,
        'solde_initial': double.parse(_soldeCtrl.text.replaceAll(',', '.')),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Modification impossible : ${e.toString()}");
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Modifier l\'espace',
                style: AppFonts.heading(
                    fontSize: 18, color: AppColors.texteEncre)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _devise,
              decoration: const InputDecoration(labelText: 'Devise'),
              items: const [
                DropdownMenuItem(value: 'XOF', child: Text('FCFA (XOF)')),
                DropdownMenuItem(value: 'XAF', child: Text('FCFA CEMAC (XAF)')),
                DropdownMenuItem(value: 'GHS', child: Text('Cedi (GHS)')),
                DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
                DropdownMenuItem(value: 'USD', child: Text('Dollar (USD)')),
              ],
              onChanged: (v) => setState(() => _devise = v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _soldeCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Solde initial'),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                return n == null ? 'Montant invalide' : null;
              },
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: const TextStyle(color: AppColors.terre)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enCours ? null : _enregistrer,
              child: _enCours
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
  }
}
