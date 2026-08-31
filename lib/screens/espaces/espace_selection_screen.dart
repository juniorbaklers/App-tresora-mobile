import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/espace.dart';
import '../../models/invitation.dart';
import '../../providers/auth_providers.dart';
import '../../providers/espace_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bandeau_hors_ligne.dart';
import '../../widgets/motif.dart';
import '../auth/login_screen.dart';
import '../home/home_shell.dart';
import '../../utils/erreurs.dart';

/// Premier écran après connexion : choisir l'espace à gérer (ou en créer
/// un). Chaque espace est une trésorerie indépendante — c'est le concept
/// central de Trésora.
class EspaceSelectionScreen extends ConsumerWidget {
  const EspaceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espacesAsync = ref.watch(mesEspacesProvider);
    final invitations = ref.watch(mesInvitationsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes espaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await ref.read(authServiceProvider).deconnexion();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _ouvrirFormulaireCreation(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nouvel espace'),
      ),
      body: Column(
        children: [
          const BandeauHorsLigne(),
          Expanded(
            child: espacesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : ${messageErreur(e)}')),
              data: (espaces) {
                if (espaces.isEmpty && invitations.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                              width: 120,
                              child: BandeTissee(
                                  tonalite: Tonalite.mixte, epaisseur: 4)),
                          const SizedBox(height: 20),
                          Text(
                            'Aucun espace pour l\'instant',
                            style: AppFonts.heading(
                                fontSize: 20, color: AppColors.texteEncre),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Crée ton église, ton groupe ou ton association pour commencer.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.texteSecondaire),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (invitations.isNotEmpty) ...[
                      Text('INVITATIONS REÇUES',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.texteSecondaire,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      for (final invitation in invitations) ...[
                        _CarteInvitation(invitation: invitation),
                        const SizedBox(height: 12),
                      ],
                      if (espaces.isNotEmpty) const SizedBox(height: 8),
                    ],
                    for (final (i, e) in espaces.indexed) ...[
                      _CarteEspace(
                        espaceAvecRole: e,
                        index: i,
                        onTap: () {
                          ref.read(currentEspaceIdProvider.notifier).state =
                              e.espace.id;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const HomeShell()),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _ouvrirFormulaireCreation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FormulaireNouvelEspace(),
    );
  }
}

class _CarteInvitation extends ConsumerStatefulWidget {
  final Invitation invitation;

  const _CarteInvitation({required this.invitation});

  @override
  ConsumerState<_CarteInvitation> createState() => _CarteInvitationState();
}

class _CarteInvitationState extends ConsumerState<_CarteInvitation> {
  bool _enCours = false;

  Future<void> _accepter() async {
    setState(() => _enCours = true);
    try {
      final espaceId = await ref
          .read(invitationsServiceProvider)
          .accepter(widget.invitation.id);
      if (!mounted) return;
      ref.read(currentEspaceIdProvider.notifier).state = espaceId;
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Acceptation impossible : ${messageErreur(e)}")));
        setState(() => _enCours = false);
      }
    }
  }

  Future<void> _refuser() async {
    setState(() => _enCours = true);
    try {
      await ref
          .read(invitationsServiceProvider)
          .supprimer(widget.invitation.id);
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.carte,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.or),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.invitation.nomEspace ?? 'Espace',
              style:
                  AppFonts.heading(fontSize: 16, color: AppColors.texteEncre)),
          const SizedBox(height: 2),
          Text('Invité comme ${widget.invitation.role.libelle}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.texteSecondaire)),
          const SizedBox(height: 12),
          if (_enCours)
            const Center(
                child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: _refuser, child: const Text('Refuser')),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                      onPressed: _accepter, child: const Text('Accepter')),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Carte d'espace — d'après la maquette « Mes espaces » du canvas de
/// design : carte plate, lisière tissée en accent, pastille d'initiales.
/// Pas de solde affiché ici : l'app n'a pas de solde agrégé par espace en
/// dehors de l'espace courant (le calculer pour chaque espace de la liste
/// nécessiterait une requête par espace, ce que la rule flutter.md interdit
/// sans un vrai `fetchPourXxx(List<String> ids)` groupé).
class _CarteEspace extends StatelessWidget {
  final EspaceAvecRole espaceAvecRole;
  final int index;
  final VoidCallback onTap;

  const _CarteEspace(
      {required this.espaceAvecRole, required this.index, required this.onTap});

  static const _tonalites = [
    Tonalite.or,
    Tonalite.palme,
    Tonalite.terre,
    Tonalite.indigo,
    Tonalite.mixte
  ];

  @override
  Widget build(BuildContext context) {
    final espace = espaceAvecRole.espace;
    final tonalite = _tonalites[index % _tonalites.length];

    return Material(
      color: AppColors.carte,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.bordure),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              LisiereVerticale(tonalite: tonalite, epaisseur: 5),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.graphite,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          espace.initiales,
                          style: const TextStyle(
                              color: AppColors.or, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(espace.nom,
                                style: AppFonts.heading(
                                    fontSize: 16, color: AppColors.texteEncre)),
                            const SizedBox(height: 2),
                            Text(
                              '${espace.type.libelle} · ${espaceAvecRole.role.libelle}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.texteSecondaire),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.texteSecondaire),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormulaireNouvelEspace extends ConsumerStatefulWidget {
  const _FormulaireNouvelEspace();

  @override
  ConsumerState<_FormulaireNouvelEspace> createState() =>
      _FormulaireNouvelEspaceState();
}

class _FormulaireNouvelEspaceState
    extends ConsumerState<_FormulaireNouvelEspace> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  EspaceType _type = EspaceType.eglise;
  String _devise = 'XOF';
  bool _enCours = false;
  String? _erreur;

  Future<void> _creer() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final espace = await ref.read(espacesServiceProvider).creer(
            nom: _nomCtrl.text.trim(),
            type: _type,
            devise: _devise,
            createdBy: user.id,
          );
      ref.read(currentEspaceIdProvider.notifier).state = espace.id;
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeShell()));
      }
    } catch (e) {
      setState(() => _erreur = "Création impossible : ${messageErreur(e)}");
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
            Text('Nouvel espace',
                style: AppFonts.heading(
                    fontSize: 20, color: AppColors.texteEncre)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<EspaceType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: EspaceType.values
                  .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t.libelle)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v!),
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
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: const TextStyle(color: AppColors.terre)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _enCours ? null : _creer,
              child: _enCours
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('CRÉER'),
            ),
          ],
        ),
      ),
    );
  }
}
