import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/invitation.dart';
import '../../models/membre.dart';
import '../../models/role.dart';
import '../../providers/auth_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/role_gate.dart';
import 'membre_detail_screen.dart';
import 'membre_form_screen.dart';
import '../../utils/erreurs.dart';

class MembresListScreen extends ConsumerWidget {
  const MembresListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membresAsync = ref.watch(membresStreamProvider);
    final invitationsAsync = ref.watch(invitationsEspaceStreamProvider);
    final invitationsEnAttente =
        (invitationsAsync.valueOrNull ?? []).where((i) => !i.acceptee).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membres'),
        actions: [
          RoleGate(
            peutAcceder: (r) => r.peutAdministrer,
            child: IconButton(
              icon: const Icon(Icons.mail_outline),
              tooltip: 'Inviter par email',
              onPressed: () => _ouvrirFormulaireInvitation(context),
            ),
          ),
        ],
      ),
      floatingActionButton: RoleGate(
        peutAcceder: (r) => r.peutGererMembres,
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
        error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
        data: (membres) {
          if (membres.isEmpty && invitationsEnAttente.isEmpty) {
            return const Center(child: Text('Aucun membre enregistré'));
          }
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (invitationsEnAttente.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text('INVITATIONS EN ATTENTE',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.texteSecondaire,
                          fontWeight: FontWeight.w700)),
                ),
                for (final invitation in invitationsEnAttente)
                  _InvitationTile(invitation: invitation),
                const SizedBox(height: 12),
              ],
              for (final membre in membres) ...[
                _MembreTile(membre: membre),
                const SizedBox(height: 6),
              ],
            ],
          );
        },
      ),
    );
  }

  void _ouvrirFormulaireInvitation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FormulaireInvitation(),
    );
  }
}

class _InvitationTile extends ConsumerWidget {
  final Invitation invitation;

  const _InvitationTile({required this.invitation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
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
            decoration: BoxDecoration(
              color: AppColors.fond,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.mail_outline,
                size: 19, color: AppColors.texteSecondaire),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invitation.email,
                    style: AppFonts.heading(
                        fontSize: 13, color: AppColors.texteEncre)),
                const SizedBox(height: 3),
                Text('Invité comme ${invitation.role.libelle}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.texteSecondaire)),
              ],
            ),
          ),
          RoleGate(
            peutAcceder: (r) => r.peutAdministrer,
            child: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Annuler l\'invitation',
              onPressed: () => ref
                  .read(invitationsServiceProvider)
                  .supprimer(invitation.id),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormulaireInvitation extends ConsumerStatefulWidget {
  const _FormulaireInvitation();

  @override
  ConsumerState<_FormulaireInvitation> createState() =>
      _FormulaireInvitationState();
}

class _FormulaireInvitationState extends ConsumerState<_FormulaireInvitation> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  RoleEspace _role = RoleEspace.membre;
  bool _enCours = false;
  String? _erreur;

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;
    final espaceId = ref.read(currentEspaceIdProvider);
    final user = ref.read(currentUserProvider);
    if (espaceId == null || user == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await ref.read(invitationsServiceProvider).inviter(Invitation(
            id: '',
            espaceId: espaceId,
            email: _emailCtrl.text.trim(),
            role: _role,
            inviteParId: user.id,
            date: DateTime.now(),
            acceptee: false,
          ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _erreur = "Invitation impossible : ${messageErreur(e)}");
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
            Text('Inviter par email',
                style: AppFonts.heading(
                    fontSize: 18, color: AppColors.texteEncre)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<RoleEspace>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: RoleEspace.values
                  .where((r) => r != RoleEspace.proprietaire)
                  .map(
                      (r) => DropdownMenuItem(value: r, child: Text(r.libelle)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v!),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: const TextStyle(color: AppColors.terre)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enCours ? null : _envoyer,
              child: _enCours
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('INVITER'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembreTile extends ConsumerWidget {
  final Membre membre;

  const _MembreTile({required this.membre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.carte,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => MembreDetailScreen(membre: membre)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.bordure),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: membre.actif
                      ? AppColors.palme.withValues(alpha: .12)
                      : AppColors.texteSecondaire.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.person,
                    size: 19,
                    color: membre.actif
                        ? AppColors.palme
                        : AppColors.texteSecondaire),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(membre.nomComplet,
                        style: AppFonts.heading(
                            fontSize: 13,
                            color: membre.actif
                                ? AppColors.texteEncre
                                : AppColors.texteSecondaire)),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (membre.fonction?.isNotEmpty == true)
                          membre.fonction!,
                        if (membre.telephone.isNotEmpty) membre.telephone,
                      ].join(' · ').ifEmpty('Pas de détails'),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.texteSecondaire),
                    ),
                  ],
                ),
              ),
              RoleGate(
                peutAcceder: (r) => r.peutGererMembres,
                child: Switch(
                  value: membre.actif,
                  onChanged: (v) => ref
                      .read(membresServiceProvider)
                      .modifier(membre.id, {'statut': v ? 'actif' : 'inactif'}),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _StringVide on String {
  String ifEmpty(String remplacement) => isEmpty ? remplacement : this;
}
